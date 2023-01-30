// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <8.10.0;

contract DataShare{
    struct Video {
        uint256 _id;
        MetaData metData;
        uint256 _price;
        address _creator;
        uint256 _commission;
        bool approved;
        uint256 _time;
    }

    struct MetaData {
        string name;
        string description;
        string category;
        string genre;
        string _type;
        string _url;
        string preview;
        string poster;
        uint256 _duration;
    }

    struct Activity{
      address _address;
      uint256 _id;
      uint256 _time;
      string _status;
    }
}