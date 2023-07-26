//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "contracts/ERC721SW.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GlitchGirlsReloaded is ERC721SW, Ownable {
    address internal _GGContractAddress;

    mapping(address => int256) internal _freeGGs;

    uint256 internal GG_PRICE = 0.05 ether;

    bool internal minting = false;
    bool internal migrating = false;
    uint256 internal MAXBATCH = 15;

    uint256 public constant TOTALGGS = 6969;
    uint256 public constant DEV_HOLDBACK = 69;
    uint256 public constant GGPUBLIC = TOTALGGS - DEV_HOLDBACK;

    string internal _tokenBaseURI;

    function adjustPrice(uint256 newPrice) external onlyOwner {
        GG_PRICE = newPrice;
    }

    function addToWhiteList(
        address[] calldata entries,
        uint256[] calldata amountAllowed
    ) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            _freeGGs[entry] = int256(amountAllowed[i]);
        }
    }

    function adjustMaxBatch(uint256 maxBatch) external onlyOwner {
        MAXBATCH = maxBatch;
    }

    function toggleMint(bool isMigrate) external onlyOwner {
        if (isMigrate) {
            migrating = !migrating;
        } else {
            minting = !minting;
        }
    }

    function removeFromWhiteList(address[] calldata entries)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            _freeGGs[entry] = 0;
        }
    }

    constructor(
        address startingContractAddress,
        uint256 startingTokenId,
        string memory baseURI
    ) ERC721SW("Glitch Girls Reloaded", "GG2") {
        _GGContractAddress = startingContractAddress;
        _currentIndex = startingTokenId;
        _tokenBaseURI = baseURI;
    }

    function changeGGContractAddress(address newContractAddress) public {
        _GGContractAddress = newContractAddress;
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(_currentIndex + receivers.length <= TOTALGGS, "1");

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], 1, _currentIndex);
        }
    }

    address private withdrawAccount = 0x3586218D139C2fd5eC9445E13FFC466D5bB5aa8c;

    modifier withdrawAddressCheck() {
        require(msg.sender == withdrawAccount, "No.");
        _;
    }

    function currentWhitelistSpots(address user) external view returns (int256) {
        return _freeGGs[user];
    }

    function currentMaxBatch() external view returns (uint256) {
        return MAXBATCH;
    }

    function currentGGContract() external view returns(address) {
        return _GGContractAddress;
    }
    function isMinting() external view returns(bool) {
        return minting;
    }

    function isMigrating() external view returns(bool) {
        return migrating;
    }

    function currentPrice() external view returns(uint256) {
        return GG_PRICE;
    }

    function totalBalance() external view returns (uint256) {
        return payable(address(this)).balance;
    }

    function withdrawFunds() external withdrawAddressCheck {
        payable(msg.sender).transfer(this.totalBalance());
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721SW)
        returns (string memory)
    {
        require(_exists(tokenId), "1");

        return
            string(
                abi.encodePacked(
                    _tokenBaseURI,
                    Strings.toString(tokenId),
                    string(".json")
                )
            );
    }

    function GGMint(
        uint256 qty,
        bool freeGG
    ) external payable {
        if (!minting) revert("Not minting");
        address to = msg.sender;
        if (freeGG) {
            if (_freeGGs[to] - int256(qty) < 0) revert("No free ggs");
        } else {
            if (msg.value < (GG_PRICE * qty)) revert("Not enough eth");
        }
        
        if (qty > MAXBATCH) revert("Max batch limit");
        if ((_currentIndex + qty) > GGPUBLIC) revert("No supply");

        _safeMint(to, qty, _currentIndex);

        if (freeGG) {
            _freeGGs[to] -= int256(qty);
        }
    }

    function GGMigrate(
        uint256 glitchGirlToken,
        uint256 qty
    ) public {
        if (!migrating) revert("Not migrating");
        address to = msg.sender;
        GGContractTrait GGContract = GGContractTrait(_GGContractAddress);
        
        for (uint256 i = glitchGirlToken; i < glitchGirlToken+qty; i++) {
            address ownerOf = GGContract.ownerOf(i);

            if (ownerOf != to) revert("Doesnt own token");
            
            if (_exists(i)) revert("Already migrated");
        }
        _safeMint(to, qty, glitchGirlToken);
    
        _freeGGs[to] += int256(qty);
    }
}

abstract contract GGContractTrait {
    function ownerOf(uint256 tokenId) external view virtual returns (address);
}