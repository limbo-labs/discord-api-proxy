import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  stages: [
    { duration: '5s', target: 250 },
    { duration: '5s', target: 500 },
    { duration: '5m', target: 500 },
  ],
};

export default function () {
  const BASE_URL = 'http://127.0.0.1:8080/api/v10'; // make sure this is not production

  let req = {
    method: 'GET',
    url: `${BASE_URL}/gateway`,

    params: {
      headers: {
        Authorization: `Bot ${__ENV.TOKEN}`
      }
    }
  };
     
  const responses = http.batch([
    req, req, req, req
  ]);

  sleep(1);
}
