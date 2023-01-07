//SPDX-License-Identifier: Unlicense



/*

HAPPY NEW YEAR NERDS 

 __   __  __   __  ______    _______  ___  
|  | |  ||  | |  ||    _ |  |       ||   | 
|  |_|  ||  | |  ||   | ||  |    ___||   | 
|       ||  |_|  ||   |_||_ |   |___ |   | 
|_     _||       ||    __  ||    ___||   | 
  |   |  |       ||   |  | ||   |___ |   | 
  |___|  |_______||___|  |_||_______||___| 


*/

pragma solidity 0.8.15;

import "https://github.com/DonkeVerse/ERC1155D/blob/main/contracts/ERC1155D.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YureiDayAndNight is ERC1155, Ownable {

    constructor(string memory uri) ERC1155(uri) {
        _setURI(uri);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function Bless(uint256 _id, address[] calldata _nerds)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _nerds.length; i++) {
            _mint(_nerds[i], _id, 1, "");
        }
    }


    function batchMint(
        uint256 _tokenID,
        address _address,
        uint256 _quantity
    ) external onlyOwner {
        _mint(_address, _tokenID, _quantity, "");
    }
}