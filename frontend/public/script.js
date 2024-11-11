document.addEventListener('DOMContentLoaded', () => {
    const resultElement = document.getElementById('result');
    const getCountry = document.getElementById('get-country')
    const addCountry = document.getElementById('add-country')
    const clearButton = document.getElementById('clear')
    const countryInput =document.getElementById('country')
    const getCountries = document.getElementById('get-all-countries')
    const getPastCountries = document.getElementById('past-countries')
    const deletePastCountries = document.getElementById('delete-past-countries')

    getCountry.addEventListener('click', () => {
        const countryID = countryInput.value.trim()
        const requestBody = {
            countryID : countryID
        };
        console.log(requestBody);

        const url = '/api/getcountry';
        fetch(url, {
            method: "POST",
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestBody)
        })
        .then(response => response.json())
        .then(data => {
            console.log(data);
            let tableHTML = `<table border="1">
                            <tr>
                                <th>ID</th>
                                <th>Name</th>
                                <th>Timezones</th>
                            </tr>`;
        
            // Populate the table with data (assuming data is an object containing id, name, and timezones)
            tableHTML += `<tr>
                            <td>${data.id}</td>
                            <td>${data.name}</td>
                            <td>${data.timezones.join(', ')}</td>
                        </tr>`;
            
            // Close the table
            tableHTML += `</table>`;

            // Display the table in the result element
            resultElement.innerHTML = tableHTML;

        })
        .catch(error => console.error('Error fetching data:', error));
    });

    getCountries.addEventListener('click', ()=>{
        console.log('Button clicked, fetching countries...');
        const url = '/api/getallcountries' //if this route is '/api/getcountries' it wont work. later check why

        console.log(`fetching data from ${url}`);
        

        fetch(url, {
            method: "GET",
            headers: {
                'Content-Type': 'application/json'
            },
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok: ' + response.status);
            }
            return response.json();
        })
        .then(data => {
            console.log(data); // Check the data received
            let tableHTML = `<table border="1">
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Timezones</th>
            </tr>`;
        
            Object.values(data).forEach(country => {
                tableHTML += `<tr>
                                <td>${country.id}</td>
                                <td>${country.name}</td>
                                <td>${country.timezones.join(', ')}</td>
                              </tr>`;
            });
        
            tableHTML += `</table>`;
            resultElement.innerHTML = tableHTML;
        })
        .catch(error => {
            console.error('Error fetching countries:', error);
        });
        
    })

    getPastCountries.addEventListener('click', ()=>{
        const url = '/api/previouscountries'

        fetch(url, {
            method: "GET",
            headers: {
                'Content-Type': 'application/json'
            },
        })
        .then(response=> response.json())
        .then(data => {
            console.log(data);
            let tableHTML = `<table border="1">
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Timezones</th>
            </tr>`;

            // Populate the table with data (assuming data is an object containing id, name, and timezones)
            Object.values(data).forEach(country => {
                tableHTML += `<tr>
                                <td>${country.id}</td>
                                <td>${country.name}</td>
                                <td>${country.timezones.join(', ')}</td>
                              </tr>`;
            });

            // Close the table
            tableHTML += `</table>`;

            // Display the table in the result element
            resultElement.innerHTML = tableHTML;
        })
    })
    deletePastCountries.addEventListener('click', ()=>{
        const url = '/api/deletepreviouscountries'

        fetch(url, {
            method: "GET",
            headers: {
                'Content-Type': 'application/json'
            },
        })
        .then(response=> response.json())
        .then(data => {
            console.log(data);
          
        })
    })

    clearButton.addEventListener('click', ()=>{
        resultElement.innerHTML = ''
        countryInput.value = ''
    })
});
