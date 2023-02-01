pragma solidity ^0.8.0;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2022 Debond Protocol <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

import "./AbstractDNFT.sol";


contract DNFT0 is AbstractDNFT {

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _notRevealedURI,
        string memory __baseURI,
        uint _totalSupply
    ) AbstractDNFT(_name, _symbol, _totalSupply) {}
}