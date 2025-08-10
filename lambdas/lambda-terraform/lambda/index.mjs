console.log('Loading function');

export const handler = async (event, context) => {
    //console.log('Received event:', JSON.stringify(event, null, 2));
    console.log('value1 =', event.key1);
    console.log('value2 =', event.key2);
    console.log('value3 =', event.key3);

    //add the values 2 and 3
    const sum = event.key3 + event.key2;

    console.log('Sum of == key2 and key3:', sum);
    return event.key1;  // Echo back the first key value
    // throw new Error('Something went wrong');
};
