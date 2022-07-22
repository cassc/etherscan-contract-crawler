//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


/* solhint-disable indent */


struct Trait {
    string displayType;
    string key;
    string value;
}

struct MetadataContract {
    string _name;
    string _symbol;
    string _description;
    string _imageName;
    string _externalUri;
}