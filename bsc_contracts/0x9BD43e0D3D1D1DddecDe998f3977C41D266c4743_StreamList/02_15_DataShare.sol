// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <8.10.0;

contract DataShare{
    struct File {
        uint256 _id;
        MetaData metData;
        uint256 _price;
        address _creator;
        uint256 _commission;
        bool approved;
        uint256 _time;
        bool _promoted;
        Rate[] _rates;
    }

    struct MetaData {
        string name;
        string description;
        string category;
        string _type;
        string file;
        string[] screenshots;
        string[] compatibility;
        string thumbnail;
    }

    struct Activity{
      address _address;
      uint256 _id;
      uint256 _time;
      string _status;
    }

    struct Rate{
        address _address;
        string _rate;
        string _stars;
        string _reason;
    }
}