#Common PS queries and ways to display/export data

#String manipulation:
    #Split
        "Hello how are you?" -split(' ')
    #Join
        "Hello how are you?" -split(' ') -join('_')
    #Replace
        ("Hello how are you?").Replace('are you','is everyone')
    #Substring
        ("Hello how are you?").Substring(0,5)

#AD: get-aduser, get-adcomputer, search-aduser
    #Get-ADUser
        Get-ADUser alice
        Get-ADUser alice -Server wingtiptoys.com -Properties * #check a user in a different domain and get all the properties 
    #Which user objects start with 'svc'
        Get-ADUser -Filter {samaccountname -like "svc*"}
    #Great, but I really just care about how many
        Get-ADUser -Filter {samaccountname -like "svc*"} | Measure-Object
    #How many active users are there?
        #depends on how you define 'active' and which user objects you want to include... lets take a look at a few ways
            Get-ADUser -Filter{enabled -eq $true} | measure #get all enabled user objects... measure is an alias for measure-object
            Get-ADUser -Filter{enabled -eq $true -and SamAccountName -notlike "*svc*"} | measure #get all enabled user objects but ignore service accounts
            Get-ADUser -Filter{enabled -eq $true -and SamAccountName -notlike "*svc*" -and SamAccountName -notlike "admin-*"} | measure #get all enabled user objects but ignore service accounts and admins
            $TestDate = (Get-Date).AddDays(-90)
            Get-ADUser -Filter{enabled -eq $true -and SamAccountName -notlike "*svc*" -and SamAccountName -notlike "admin-*" -and LastLogonDate -gt $TestDate} | measure #get all enabled user objects but ignore service accounts and admins, but only if they have logged in recenly
            Get-ADUser -Filter{enabled -eq $true -and SamAccountName -notlike "*svc*" -and SamAccountName -notlike "admin-*" -and LastLogonDate -gt $TestDate} | Where-Object{$_.distinguishedName -notlike "*OU=DisabledAccounts,DC=contoso,DC=com"} | measure #get all enabled user objects but ignore service accounts and admins, but only if they have logged in recenly, and ignore accounts in the DisabledAccounts OU
                #Note that DistinguishedName is calculated at runtime, not stored as part of the user object so a Where-Object must be used to filter on it instead of using filter
                #When there are a small number of items it doesn't matter, but Filter is much faster than Where-Object.  Filter is not availble on all cmdlets though.
        #Search-ADUser
            Search-ADAccount -UsersOnly -LockedOut #finds locked out users
            Search-ADAccount -UsersOnly -PasswordExpired #finds users with an expired password
            Search-ADAccount -UsersOnly -AccountDisabled #finds disabled users

    #Get-ADComputer
        Get-ADComputer (hostname)
        Get-ADComputer (hostname) -Properties operatingsystem
        #how many of each OS do we have?
            Get-ADComputer -Properties OperatingSystem -Filter * | Group-Object OperatingSystem | Select-Object count,Name | Sort-Object count -Descending
        #I only care about servers though
            Get-ADComputer -Properties OperatingSystem -Filter {OperatingSystem -like "*server*"} | Group-Object OperatingSystem | Select-Object count,Name | Sort-Object count -Descending
        #How many servers of each "type" do i have based on naming convention?
            Get-ADComputer -Filter {operatingsystem -like "*server*"} -Properties OperatingSystem | select @{Name="Type";Expression={$_.name.split('-')[1]}} | group Type | select count,name | Sort-Object count #this is if servernames have the format <first section>-<type>-<other stuff>  #Can you figure out how to group based on <first section>?
        #Which OUs have computers with a server OS in them?
            #lets practice getting the info we want with a single object first:
                (Get-ADComputer (hostname)).distinguishedName #yay, we have the data, but it has extra stuff, we don't want the computer name, just the OU
                $a = ((Get-ADComputer (hostname)).distinguishedName.split(',')) #cool, we have the bits we want, just need to put together the parts we care about
                $a[1..$($a.count)] -join(',')
            #but I want it for all my computers, not just 1 - this means we get to play with named expressions again
                Get-ADComputer -Filter {OperatingSystem -like "*server*"} -Properties OperatingSystem | select @{N="OU";E={$a = $_.distinguishedName.split(',');$a[1..$($a.count)] -join(',')}} | group OU | select count,name #N and E can be used instead of Name and Expression to make your named expressions easier to write
            #Now the boss says this is too hard to read and to only include the name of the OU the server is in, not all the parent OUs
                #try for 1 computer to learn
                    (Get-ADComputer (hostname)).distinguishedName.split(',')[1] #this is close but has OU= at the beginning
                    (Get-ADComputer (hostname)).distinguishedName.split(',')[1].replace('OU=','') #yay, it looks good
                #now do it for all computers
                    Get-ADComputer -Filter {OperatingSystem -like "*server*"} -Properties OperatingSystem | select @{N="OU";E={($_.distinguishedName.split(',')[1]).replace('OU=','')}} | group OU | select count,name
            #Oh no, there are still 2012 servers... lets find out more info
                #are they still connecting to the network?
                    Get-ADComputer -Properties operatingsystem,lastlogondate -Filter{operatingsystem -like "*2012*"} | select name,lastlogondate
                #are they online right now?
                    Get-ADComputer -Properties operatingsystem,dnshostname -Filter{operatingsystem -like "*2012*"} | %{Test-NetConnection $_.dnshostname -port 3389 | select computername,TcpTestSuccceeded}
                #Lets do it another way because we want to see the lastlogondate and test-netconnection test at the same time
                    Get-ADComputer -Properties operatingsystem,dnshostname,lastlogondate -Filter{operatingsystem -like "*2012*"} | select Name, LastLogonDate, @{N="TcpTestSuccceeded";E={(Test-NetConnection $_.dnshostname -Port 3389).TcpTestSuccceeded}}

#Cool, what about stuff outside of AD?
    #Files
        $MyPath = "C:\Users\Alice\" #stick a path to some folder with some files here - if it is very big then execution will take a long time
        #how many files do I have in $MyPath?
            Get-ChildItem $MyPath -Recurse -File | Measure-Object
        #how many directories?
            Get-ChildItem $MyPath -Recurse -Directory | Measure-Object
        #how many .exe files are there?
            Get-ChildItem $MyPath -Recurse -File -Include "*.exe" | Measure-Object
        #I care about both .exe and .ps1 now
            Get-ChildItem $MyPath -Recurse -File -Include @("*.exe","*.ps1") | Measure-Object
        #I want to exclude files with test in the name though
            Get-ChildItem $MyPath -Recurse -File -Include @("*.exe","*.ps1") -Exclude "*test*" | Measure-Object
        #I only care about new files though
            Get-ChildItem $MyPath -Recurse -File -Include @("*.exe","*.ps1") -Exclude "*test*" | Where{$_.CreationTime -gt (get-date "1/1/2021")} | Measure-Object
        #Now I want to know how big all of these files are
            Get-ChildItem $MyPath -Recurse -File -Include @("*.exe","*.ps1") -Exclude "*test*" | Where{$_.CreationTime -gt (get-date "1/1/2021")} | Measure-Object -Property Length -Sum
        #But I'm a human, don't give it to me in bytes
        (Get-ChildItem $MyPath -Recurse -File -Include @("*.exe","*.ps1") -Exclude "*test*" | Where{$_.CreationTime -gt (get-date "1/1/2021")} | Measure-Object -Property Length -Sum).sum/1mb

    #Registry
        Get-ChildItem 'HKCU:\Control Panel'
        Get-Item 'HKCU:\Control Panel\Keyboard'
        Get-ItemProperty 'HKCU:\Control Panel\Keyboard'
        (Get-ItemProperty 'HKCU:\Control Panel\Keyboard').KeyboardDelay

#differences between ' and "
$a = 'some text'
"$a - test"
'$a - test'
# " allows wildcards, data is not treated as a literal
# ' does not allow wildcards, means exactly what the literal says

#extra tips and tricks
    #<ctrl>+space
    #<ctrl>+r #from regular host, not the ISE
    #.GetType()
    Get-Member
    Out-GridView #also with -PassThrough

