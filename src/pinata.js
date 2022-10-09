// require('dotenv').config();

const key = process.env.REACT_APP_PINATA_KEY;
const secret = process.env.REACT_APP_PINATA_SECRET;

const axios = require("axios");
const FormData = require("form-data");

export const uploadJSONToIPFS = async (JSONBody) => {
  const url = `https://api.pinata.cloud/pinning/pinJSONToIPFS`;
  return axios
    .post(url, JSONBody, {
      headers: {
        pinata_api_key: key,
        pinata_secret_api_key: secret,
      },
    })
    .then((res) => {
      return {
        success: true,
        pinataURL: "https://gateway.pinata.cloud/ipfs/" + res.data.IpfsHash,
      };
    })
    .catch((e) => {
      console.log(e);
      return {
        success: false,
        message: e.message,
      };
    });
};

export const uploadFileToIPFS = async (file) => {
  const url = `https://api.pinata.cloud/pinning/pinFileToIPFS`;
  let data = new FormData();
  data.append("file", file);

  const metadata = JSON.stringify({
    name: "testname",
    keyvalues: {
      exampleKey: "exampleValue",
    },
  });
  data.append("pinataMetadata", metadata);

  const pinataOptions = JSON.stringify({
    cidVersion: 0,
    customPinPolicy: {
      regions: [
        {
          id: "FRA1",
          desiredReplicationCount: 1,
        },
        {
          id: "NYC1",
          desiredReplicationCount: 2,
        },
      ],
    },
  });
  data.append("pinataOptions", pinataOptions);

  return axios
    .post(url, data, {
      maxBodyLength: "Infinity",
      headers: {
        "Content-Type": `multipart/form-data; boundary=${data._boundary}`,
        pinata_api_key: key.toString(),
        pinata_secret_api_key: secret.toString(),
      },
    })
    .then((res) => {
      console.log("image uploaded", res.data.IpfsHash);
      return {
        success: true,
        pinataURL: "https://gateway.pinata.cloud/ipfs/" + res.data.IpfsHash,
      };
    })
    .catch((e) => {
      console.log(e);
      return {
        success: false,
        message: e.message,
      };
    });
};
