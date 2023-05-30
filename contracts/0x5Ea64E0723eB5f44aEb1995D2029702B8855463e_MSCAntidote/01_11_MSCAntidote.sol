// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*   
            __  _     __      __     
  ____ _____  / /_(_)___/ /___  / /____ 
 / __ `/ __ \/ __/ / __  / __ \/ __/ _ \
/ /_/ / / / / /_/ / /_/ / /_/ / /_/  __/
\__,_/_/ /_/\__/_/\__,_/\____/\__/\___/                              

*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MSCAntidote is ERC1155, Ownable {
    using Strings for uint256;

    string public name;
    string public symbol;

    mapping(uint256 => bool) public tokenURI;
    
    address private mutationContract;
    string private baseURI;

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
        name = "MSC Antidote";
        symbol = "MSCA";
        tokenURI[0] = true;
    }

    function mint(uint256 _id, uint256 _amount)
        external
        onlyOwner
    {
        _mint(owner(), _id, _amount, "");
    }

    function setMutationContractAddress(address _mutationContractAddress)
        external
        onlyOwner
    {
        mutationContract = _mutationContractAddress;
    }

    function burnAntidoteForAddress(uint256 _id, address _burnForAddress)
        external
    {
        require(msg.sender == mutationContract, "Invalid burner address");
        _burn(_burnForAddress, _id, 1);
    }

    function setURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 _id)
        public
        view                
        override
        returns (string memory)
    {
        require(
            tokenURI[_id],
            "URI requested for invalid antidote type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _id.toString()))
                : baseURI;
    }
}