// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CRAZYCOWS is ERC1155, Ownable, Pausable {
    using SafeMath for uint256;

    string public constant name = "CRAZY COWS";
    string public constant symbol = "CCOW";
    uint256 public totalSupply = 0;
    uint256 public constant maxSupply = 5500;
    uint256 public mintPrice = 0.015 ether;

    uint256 public constant maxPreSale = 500;
    uint256 public constant maxPubSale = 5000;
    uint256 public lockedEnded;
    uint256 public startedTime;
    uint256 public updatedTime;
    uint256 public presaleEnded;
    uint256 public lockedPeriod = 30 days;
    uint256 public presalePeriod = 3 days;
    address payable[] internal allowedAddresses;
    mapping(address => bool) public whitelist;

    error NFT__ContractIsPaused();
    error NFT__InvalidMintAmount();
    error NFT__MaxSupplyExceeded();
    error NFT__NotWhitelisted(address user);
    error NFT__InsufficientFunds();

    constructor()
        ERC1155("ipfs://QmRikT2ZWmXubj8iY3QquFATCYis75MxXvNa1AcPH1yhcx/{id}")
    {
        startedTime = block.timestamp;
        updatedTime = block.timestamp;
        lockedEnded = startedTime + lockedPeriod;
        presaleEnded = startedTime + lockedPeriod + presalePeriod;
    }

    function checkStatus() public view returns (string memory) {
        if (block.timestamp < lockedEnded || paused()) {
            return "Lock";
        } else if (
            block.timestamp >= lockedEnded && block.timestamp < presaleEnded
        ) {
            return "Pre-Sale";
        } else {
            return "Public Sale";
        }
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    function setPresalePeriod(uint256 period) public onlyOwner {
        presalePeriod = period;
        presaleEnded = updatedTime + lockedPeriod + presalePeriod;
    }

    function setLockedPeriod(uint256 period) public onlyOwner {
        lockedPeriod = period;
        updatedTime = block.timestamp;
        lockedEnded = updatedTime + lockedPeriod;
        presaleEnded = updatedTime + lockedPeriod + presalePeriod;
    }

    function getAllowedAddresses()
        public
        view
        onlyOwner
        returns (address payable[] memory)
    {
        return allowedAddresses;
    }

    function addToWhitelist(
        address payable[] calldata toAddAddresses
    ) external onlyOwner {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
            allowedAddresses.push(toAddAddresses[i]);
        }
    }

    function removeFromWhitelist(
        address payable[] calldata toRemoveAddresses
    ) external onlyOwner {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
            allowedAddresses[i] = allowedAddresses[allowedAddresses.length - 1];
            allowedAddresses.pop();
        }
    }

    function mint(uint256 amount) external payable whenNotPaused {
        if (block.timestamp < lockedEnded) {
            revert NFT__ContractIsPaused();
        } else {
            if (block.timestamp < presaleEnded) {
                require(
                    totalSupply + amount <= maxPreSale,
                    "Exceed maximum presale amount"
                );
                if (whitelist[msg.sender] || msg.sender == owner()) {
                    mintTo(msg.sender, amount);
                } else {
                    revert NFT__NotWhitelisted(msg.sender);
                }
            } else {
                mintTo(msg.sender, amount);
            }
        }
    }

    function mintTo(address to, uint256 amount) internal {
        if (totalSupply + amount > maxSupply) {
            revert NFT__MaxSupplyExceeded();
        }
        if (msg.value < mintPrice.mul(amount)) {
            revert NFT__InsufficientFunds();
        }
        if (amount > 1) {
            for (uint256 i = 0; i < amount; i++) {
                _mint(to, totalSupply + i, 1, "");
            }
        } else if (amount == 1) {
            _mint(to, totalSupply, 1, "");
        } else {
            revert NFT__InvalidMintAmount();
        }

        totalSupply += amount;
    }

    function mintBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner whenNotPaused {
        _mintBatch(msg.sender, ids, amounts, "");
        totalSupply += ids.length;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer ETH failed to owner.");
    }
}