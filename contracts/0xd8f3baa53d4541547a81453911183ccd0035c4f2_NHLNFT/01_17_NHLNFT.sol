// SPDX-License-Identifier: MIT

////$$$$$$$
//| $$__  $$
//| $$  \ $$ /$$   /$$  /$$$$$$$ /$$$$$$$
//| $$$$$$$/| $$  | $$ /$$_____//$$_____/
//| $$__  $$| $$  | $$|  $$$$$$|  $$$$$$
//| $$  \ $$| $$  | $$ \____  $$\____  $$
//| $$  | $$|  $$$$$$/ /$$$$$$$//$$$$$$$/
//|__/  |__/ \______/ |_______/|_______/

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./NhlMetaDataGenerator.sol";

contract NHLNFT is ERC721Enumerable, Ownable {
    using Strings for uint256; 

    event NewToken(address _minter, uint256 _tokenId);

    
    uint256 public supply = 0;
    address public beneficiary = 0xCe420CA2a9686512ee4E01976E1fBeCA2B5C4e99;

    

    struct Prediction {
        uint256 tokenId;
        address owner;
        string selection;
        uint256 timestamp;
        string _colorOne;
        string _colorTwo;
    }

    mapping(uint256 => Prediction) public predictions; // token id => [selection, owner, timestamp, _colorOne, colorTwo]

    constructor() ERC721("NHL Predictions", "NHLP") {
      
    }

    function mint(string calldata selection, string calldata _colorOne, string calldata _colorTwo) public payable returns (uint256) {

      uint256 tokenId = totalSupply() + 1;

      
      
      Prediction memory newPrediction = Prediction(
        tokenId, msg.sender, selection, block.timestamp, _colorOne, _colorTwo);

      predictions[tokenId] = newPrediction;

        _safeMint(msg.sender, tokenId);

        supply = supply + 1;

        emit NewToken(msg.sender, tokenId);

        return tokenId;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {

        require(_exists(id), "not exist");

        Prediction memory currentPrediction = predictions[id];

        return NhlMetaDataGenerator.tokenURI(NhlMetaDataGenerator.Prediction({
            tokenId: currentPrediction.tokenId,
            owner: currentPrediction.owner,
            selection: currentPrediction.selection,
            timestamp: currentPrediction.timestamp,
            _colorOne: currentPrediction._colorOne,
            _colorTwo: currentPrediction._colorTwo
        }));

    }

    function withdrawFunds() public {
      require(msg.sender == beneficiary, 'only beneficiary');
      uint amount = address(this).balance;

      (bool success,) = beneficiary.call{value: amount}("");
      require(success, "Failed");
    }


}