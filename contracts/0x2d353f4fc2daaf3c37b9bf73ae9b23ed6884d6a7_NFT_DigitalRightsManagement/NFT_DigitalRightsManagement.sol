/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract NFT_DigitalRightsManagement
{
    address private owner;
    Element[] private elements;
    
    constructor() {
        owner = msg.sender;
    }

    struct Element {
        string title;
        string contractAbi;
        string contractAddress;
        string tokenId;
    }
    
    function TransferOwnership(address _newOwner) public OwnerOnly {
        owner = _newOwner;
    }

    function ReadAll() public view OwnerOnly returns(Element[] memory _elements) {
        return elements;
    }

    function AddElement(string memory _title, string memory _contractAbi, string memory _contractAddress, string memory _tokenId) public OwnerOnly {
        elements.push(Element(_title, _contractAbi, _contractAddress, _tokenId));
    }

    function GetElementInfos(string memory _title) public view returns(string[3] memory _element) {
        for(uint256 i = 0; i < elements.length; i++) {
            if(keccak256(bytes(elements[i].title)) == keccak256(bytes(_title))) {
                return[elements[i].contractAbi, elements[i].contractAddress, elements[i].tokenId];
            }
        }
    }

    function RemoveElement(string memory _title) public OwnerOnly {
        for(uint256 i; i < elements.length; i++) {
            if(keccak256(bytes(elements[i].title)) == keccak256(bytes(_title))) {
                elements[i] = elements[elements.length - 1];
                elements.pop();
                break;
            }
        }
    }

    modifier OwnerOnly() {
        require(msg.sender == owner, "Owner only");
        _;
    }
}