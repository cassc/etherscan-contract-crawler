// SPDX-License-Identifier: GPL-3.0

/*
 ____  ____  _____     ___  _ ____  _        _____  _     _____      _____ _     ____  _  __ _  _      _____      _     _     ____  _  _____  _   ____  _____ _____ _____ _     
/  _ \/  __\/  __/     \  \///  _ \/ \ /\   /__ __\/ \ /|/  __/     /    // \ /\/   _\/ |/ // \/ \  /|/  __/     / \   / \ /\/   _\/ |/ /\  \//  /  _ \/  __//  __//  __// \  /|
| / \||  \/||  \        \  / | / \|| | ||     / \  | |_|||  \       |  __\| | |||  /  |   / | || |\ ||| |  _     | |   | | |||  /  |   /  \  /   | | \||  \  | |  _|  \  | |\ ||
| |-|||    /|  /_       / /  | \_/|| \_/|     | |  | | |||  /_      | |   | \_/||  \__|   \ | || | \||| |_//     | |_/\| \_/||  \__|   \  / /    | |_/||  /_ | |_//|  /_ | | \||
\_/ \|\_/\_\\____\_____/_/   \____/\____/_____\_/  \_/ \|\____\_____\_/   \____/\____/\_|\_\\_/\_/  \|\____\_____\____/\____/\____/\_|\_\/_/_____\____/\____\\____\\____\\_/  \|
                  \____\                 \____\                \____\                                       \____\                          \____\                              
*/

pragma solidity 0.8.7;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "./ERC721A/contracts/ERC721A.sol";

contract YOU_ARE_THE_FUCKING_LUCKY_DEGEN is ERC721A {
    uint256 public immutable maxSupply = 1000;
    // For Mining
    uint256 _baseDifficulty = 30;
    uint256 _difficultyBais = 60;
    uint256 immutable _baseGasLimit = 80000;
    address _owner;
    uint256 _price;
    uint256 _maxPerTx;

    /**
     * Guranted Mint FOR EACH ONE
     */
    function guranteeMint(uint256 amount) payable public {
        require(totalSupply() + 1 <= maxSupply, "Sold Out");
        require(amount <= _maxPerTx);
        uint256 cost = amount * _price;
        require(msg.value >= cost, "Pay For");
        _safeMint(msg.sender, amount);
    }
    
    /*
     * You Have Half Oppotunities Got Lucky Degen
    */
    function tryLucky() public {
        require(gasleft() > _baseGasLimit, "Need_More");       
        if (!areYouLucky()) return;
        require(msg.sender == tx.origin, "No_EOA");
        require(totalSupply() + 1 <= maxSupply, "Sold_Out");
        require(balanceOf(msg.sender) == 0, "ONLY_ONE");
        // Congratulations !!!
        // You are the fucking Lucky Degen !
        _safeMint(msg.sender, 1);
    }

    // Are You the fucking Lucky One ?
    function areYouLucky() public view returns(bool) {
        uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;
        return num > difficulty();
    }

    // Current Difficulty Of Mint.
    function difficulty() public view returns(uint256) {
        return _baseDifficulty + totalSupply() * _difficultyBais / maxSupply;
    }

    modifier onlyOwner {
        require(_owner == msg.sender, "No Permission");
        _;
    }
    constructor() ERC721A("YOU_ARE_THE_FUCKING_LUCKY_DEGEN", "MOON") {
        _owner = msg.sender;
        _price = 0.0011 ether;
        _maxPerTx = 10;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked("ipfs://QmWVbve1cZy1mjt5yUoU4rnTMjhWitQZ3bdk32xXRfoEhZ/", _toString(tokenId)));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}