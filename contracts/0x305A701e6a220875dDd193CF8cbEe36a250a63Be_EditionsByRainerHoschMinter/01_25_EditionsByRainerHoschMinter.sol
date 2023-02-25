//
//
//
////////////////////////////////////////////////////////////////////////////////////////
// __________        .__                        ___ ___                     .__       //
// \______   \_____  |__| ____   ___________   /   |   \  ____  ______ ____ |  |__    //
//  |       _/\__  \ |  |/    \_/ __ \_  __ \ /    ~    \/  _ \/  ___// ___\|  |  \   //
//  |    |   \ / __ \|  |   |  \  ___/|  | \/ \    Y    (  <_> )___ \\  \___|   Y  \  //
//  |____|_  /(____  /__|___|  /\___  >__|     \___|_  / \____/____  >\___  >___|  /  //
//         \/      \/        \/     \/               \/            \/     \/     \/   //
////////////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "./EditionsByRainerHosch.sol";

contract EditionsByRainerHoschMinter is Ownable {
    address public rainerHoschEditionsAddress = 0xadB4eCDABeeD8eBC69fA02F60cD43e8A2ce511e1;
    
    uint256 public mintTokenId = 2;

    uint256 public mintLimit = 1;
    mapping(address => uint256) private _mintCount;

    bool public isMintEnabled = false;

    constructor() {}


    function mint() public {
        require(isMintEnabled, "Mint not enabled");
        require(_mintCount[msg.sender] < mintLimit, "Mint limit reached");
        
        EditionsByRainerHosch token = EditionsByRainerHosch(rainerHoschEditionsAddress);
        address[] memory senderArray = new address[](1);
        senderArray[0] = msg.sender;

        uint256[] memory mintTokenIdArray = new uint256[](1);
        mintTokenIdArray[0] = mintTokenId;

        uint256[] memory mintTokenAmountArray = new uint256[](1);
        mintTokenAmountArray[0] = 1;

        token.airdrop(senderArray, mintTokenIdArray, mintTokenAmountArray);
    }

    function returnOwnership() public onlyOwner {
        EditionsByRainerHosch token = EditionsByRainerHosch(rainerHoschEditionsAddress);
        token.transferOwnership(msg.sender);
    }

    function getMintLimitByAddress(address _address)
        public
        view
        returns (uint256)
    {
        return mintLimit - _mintCount[_address];
    }

    function setIsMintEnabled(bool isEnabled) public onlyOwner {
        isMintEnabled = isEnabled;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setRainerHoschEditionsAddress(address newAddress) public onlyOwner {
        rainerHoschEditionsAddress = newAddress;
    }

    function setMintTokenId(uint256 tokenId) public onlyOwner {
        mintTokenId = tokenId;
    }
}