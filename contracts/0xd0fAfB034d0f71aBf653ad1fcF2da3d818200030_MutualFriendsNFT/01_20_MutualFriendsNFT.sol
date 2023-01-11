// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ERC721Royalty, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";


/// @custom:security - contact [email protected]
contract MutualFriendsNFT is ERC721Royalty, Ownable, DefaultOperatorFilterer {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Minted NFT Count
    Counters.Counter private _nftSupply;
    Counters.Counter private _teamMintedCount;
    Counters.Counter private _friendsSaleMinted;

    // Storage
    mapping(address => uint256) private _friendsSaleMintedCount;
    mapping(address => uint256) private _preSaleMintedCount;
    mapping(address => uint256) private _publicSaleMintedCount;

    mapping(address => uint256) private _addressBalances;

    address[] public _characterPassWhitelist;
    address[] public _friendsSaleWhitelist;
    address[] public _preSaleWhitelist;

    // NFT Config
    string private baseURI;
    string private preRevealTokenUri;
    uint256 public maxSupply;
    uint256 public teamSupply;
    uint256 public mintingPrice;
    bool public isRevealed;
    bool public isSaleFinalized;
    bool public isSaleGoalReached;

    // Sale Statuses
    bool public isCharacterPassSaleActive;
    bool public isFriendsSaleActive;
    bool public isPreSaleActive;
    bool public isPublicSaleActive;

    // Royalty Fee Config
    uint96 private _royalty;

    // Ownership Config
    address private _withdrawalAddress;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory ticker_,
        string memory baseURI_,
        string memory preRevealTokenUri_,
        uint256 nftMintingPrice_,
        uint256 maxSupply_,
        uint256 teamSupply_,
        uint96 royalty_,
        address withdrawalAddress_
    ) ERC721(name_, ticker_) Ownable() DefaultOperatorFilterer() {
        baseURI = baseURI_;
        preRevealTokenUri = preRevealTokenUri_;
        maxSupply = maxSupply_;
        mintingPrice = nftMintingPrice_;
        _royalty = royalty_;
        isFriendsSaleActive = false;
        isPublicSaleActive = false;
        isPreSaleActive = false;
        _withdrawalAddress = withdrawalAddress_;
        teamSupply = teamSupply_;
        isSaleFinalized = false;
        isSaleGoalReached = false;
        isCharacterPassSaleActive = false;
        _setDefaultRoyalty(withdrawalAddress_, royalty_);
    }

    function safeMint(uint8 quantity) public payable {
        require(!isSaleFinalized, "Sale is finalized all minting phases are closed");
        require(
            isCharacterPassSaleActive || isFriendsSaleActive || isPublicSaleActive || isPreSaleActive,
            "Sale is not active wait for announcement"
        );

        uint256 price = mintingPrice;

        if (isCharacterPassSaleActive) {
            require(quantity == 1, "Only one nft can be minted at this phase");
            price = 0;
        }

        require(msg.value == price * quantity, "Not enough ETH sent; check price and quantity!");

        bool characterPassEligible = _checkUserEligibilityInCharacterPassSale(msg.sender);
        (bool friendsSaleEligible, uint256 friendsSaleQty) = _checkUserEligibilityInFriendsSale(msg.sender);
        (bool preSaleEligible, uint256 preSaleQty) = _checkUserEligibilityInPresale(msg.sender);
        (bool publicSaleEligible, uint256 publicSaleQty) = _checkUserEligibilityInPublicSale(msg.sender);

        if (isCharacterPassSaleActive) {
            require(characterPassEligible, "User not eligible in Character Pass Sale or already minted allowed amount in this phase");
            _removeAddressFromCharacterPassWhitelist(msg.sender);
        }


        if (isFriendsSaleActive) {
            require(friendsSaleEligible, "User not eligible in Friends Sale or already minted allowed amount in this phase");
            require(friendsSaleQty >= quantity, "Specify amount is over the limit");
            if (friendsSaleQty == quantity) {
                _removeAddressFromFriendsWhitelist(msg.sender);
            }

        }

        if (isPreSaleActive) {
            require(preSaleEligible, "User not eligible in Pre Sale or already minted allowed amount in this phase");
            require(preSaleQty >= quantity, "Specify amount is over the limit");
            if (preSaleQty == quantity) {
                _removeAddressFromPreSaleWhitelist(msg.sender);
            }
        }

        if (isPublicSaleActive) {
            require(publicSaleEligible, "Already minted maximum allowed amount in public sale");
            require(publicSaleQty >= quantity, "Specify amount is over the limit");
        }

        for (uint8 i = 0; i < quantity; i += 1) {
            Counters.increment(_nftSupply);
            _issueNFT(msg.sender, Counters.current(_nftSupply));
        }

        _addressBalances[msg.sender] += msg.value;
    }

    function checkAddressEligibilityForMint() public view returns(bool, uint256) {

        bool characterPassEligible = _checkUserEligibilityInCharacterPassSale(msg.sender);
        (bool friendsSaleEligible, uint256 friendsSaleQty) = _checkUserEligibilityInFriendsSale(msg.sender);
        (bool preSaleEligible, uint256 preSaleQty) = _checkUserEligibilityInPresale(msg.sender);
        (bool publicSaleEligible, uint256 publicSaleQty) = _checkUserEligibilityInPublicSale(msg.sender);

        uint256 qty = 0;
        if (characterPassEligible) {
            qty = 1;
        } else if (friendsSaleEligible) {
            qty = friendsSaleQty;
        } else if (preSaleEligible) {
            qty = preSaleQty;
        } else if (publicSaleEligible) {
            qty = publicSaleQty;
        }


        return (characterPassEligible || friendsSaleEligible || preSaleEligible || publicSaleEligible, qty);
    }

    function teamMint(address receiver, uint8 quantity) public onlyOwner {
        require(
            Counters.current(_teamMintedCount) + quantity <= teamSupply,
            "Minting is not available, already minted all the NFTs"
        );


        for (uint8 i = 0; i < quantity; i += 1) {
            Counters.increment(_nftSupply);
            Counters.increment(_teamMintedCount);

            uint256 tokenId = Counters.current(_nftSupply);

            _safeMint(receiver, tokenId);

            _setTokenRoyalty(
                tokenId,
                _withdrawalAddress,
                _royalty
            );
        }

    }

    function setCharacterPassWhitelist(address[] calldata whitelistAddresses) public onlyOwner {
        for (uint256 i = 0; i < whitelistAddresses.length; i += 1) {
            _characterPassWhitelist.push(whitelistAddresses[i]);
        }
    }

    function setFriendsWhitelist(address[] calldata whitelistAddresses) public onlyOwner {
        for (uint256 i = 0; i < whitelistAddresses.length; i += 1) {
            _friendsSaleWhitelist.push(whitelistAddresses[i]);
        }
    }

    function setPreSaleWhitelist(address[] calldata whitelistAddresses) public onlyOwner {
        for (uint256 i = 0; i < whitelistAddresses.length; i += 1) {
            _preSaleWhitelist.push(whitelistAddresses[i]);
        }
    }

    function setCharacterPassSaleStatus(bool active) public onlyOwner {
        require(isCharacterPassSaleActive != active, "Nothing to change already same status");
        require(!isFriendsSaleActive, "Friends Sale is active deactivate if first");
        require(!isPreSaleActive, "Pre sale is active deactivate it first");
        require(!isPublicSaleActive, "Public sale is active deactivate it first");
        isCharacterPassSaleActive = active;
    }

    function setFriendsSaleStatus(bool active) public onlyOwner {
        require(isFriendsSaleActive != active, "Nothing to change already same status");
        require(!isCharacterPassSaleActive, "Character Pass sale is active deactivate it first");
        require(!isPreSaleActive, "Pre sale is active deactivate it first");
        require(!isPublicSaleActive, "Public sale is active deactivate it first");
        isFriendsSaleActive = active;
    }

    function setPreSaleStatus(bool active) public onlyOwner {
        require(isPreSaleActive != active, "Nothing to change already same status");
        require(!isCharacterPassSaleActive, "Character Pass sale is active deactivate it first");
        require(!isFriendsSaleActive, "Friends sale is active deactivate it first");
        require(!isPublicSaleActive, "Public sale is active deactivate it first");
        isPreSaleActive = active;
    }

    function setPublicSaleStatus(bool active) public onlyOwner {
        require(isPublicSaleActive != active, "Nothing to change already same status");
        require(!isCharacterPassSaleActive, "Character Pass sale is active deactivate it first");
        require(!isFriendsSaleActive, "Friends sale is active deactivate it first");
        require(!isPreSaleActive, "Pre sale is active deactivate it first");
        isPublicSaleActive = active;
    }

    function withdrawEther() public onlyOwner {
        require(isSaleFinalized, "Sale Should be finalized before withdrawing");
        require(isSaleGoalReached, "Sale Goal not reached cannot withdraw money");

        uint256 value = address(this).balance;

        if (value == 0) {
            return;
        }

        (bool success,) = _withdrawalAddress.call{value : value}('');
        require(success, 'Withdraw failed');
    }

    function updateMintingPrice(uint256 newPrice) public onlyOwner {
        mintingPrice = newPrice;
    }

    function finalizeSale(bool isSaleGoalReached_) public onlyOwner {
        require(!isPublicSaleActive, "Nothing to change already same status");
        require(!isCharacterPassSaleActive, "Character Pass sale is active deactivate it first");
        require(!isFriendsSaleActive, "Friends sale is active deactivate it first");
        require(!isPreSaleActive, "Pre sale is active deactivate it first");
        isSaleFinalized = true;
        isSaleGoalReached = isSaleGoalReached_;
    }

    function revealCollection() public onlyOwner {
        require(isSaleFinalized, "Sale Should be finalized before revealing collection");
        isRevealed = true;
    }

    function getRefund() public {
        require(isSaleFinalized, "Sale should be finalized");
        require(!isSaleGoalReached, "Refund not availabe because sale goal reached");
        uint256 balance = _addressBalances[msg.sender];
        require(balance > 0, "No Balance to get refund");

        _addressBalances[msg.sender] = 0;

        (bool success,) = msg.sender.call{value : balance}('');
        require(success, "Unable to send refund");
    }

    // VIEWS

    function availableForPublicMint() public view returns (uint256) {
        return maxSupply - teamSupply - Counters.current(_nftSupply);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (isRevealed) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        }

        return preRevealTokenUri;
    }

    // INTERNAL FUNCTIONS

    function _issueNFT(address minter, uint256 tokenId) internal {
        require(
            availableForPublicMint() > 0,
            "Minting is not available, already minted all the NFTs"
        );
        require(
            tokenId > 0 && tokenId <= maxSupply,
            "tokenId not in range of allowed token IDs"
        );
        _safeMint(minter, tokenId);
        if (isFriendsSaleActive) {
            _friendsSaleMintedCount[minter] += 1;
            Counters.increment(_friendsSaleMinted);
        } else if (isPreSaleActive) {
            _preSaleMintedCount[minter] += 1;
        } else if (isPublicSaleActive) {
            _publicSaleMintedCount[minter] += 1;
        }
    }

    function _checkUserEligibilityInCharacterPassSale(address minter) internal view returns (bool) {
        if (isCharacterPassSaleActive) {
            bool isInWhitelist = false;
            for (uint256 i = 0; i < _characterPassWhitelist.length; i += 1) {
                if (_characterPassWhitelist[i] == minter) {
                    isInWhitelist = true;
                    break;
                }
            }
            if (isInWhitelist) {
                return true;
            }
        }

        return false;
    }

    function _checkUserEligibilityInFriendsSale(address minter) internal view returns (bool, uint256) {
        if (isFriendsSaleActive) {
            bool isInWhitelist = false;
            for (uint256 i = 0; i < _friendsSaleWhitelist.length; i += 1) {
                if (_friendsSaleWhitelist[i] == minter) {
                    isInWhitelist = true;
                    break;
                }
            }
            if (isInWhitelist) {
                uint256 availableToMintAmount = 5 - _friendsSaleMintedCount[minter];
                if (availableToMintAmount > 0) {
                    return (true, availableToMintAmount);
                }
            }

            return (false, 0);
        }
        return (false, 0);
    }

    function _checkUserEligibilityInPresale(address minter) internal view returns (bool, uint256) {
        if (isPreSaleActive) {
            bool isInWhitelist = false;
            for (uint256 i = 0; i < _preSaleWhitelist.length; i += 1) {
                if (_preSaleWhitelist[i] == minter) {
                    isInWhitelist = true;
                    break;
                }
            }
            if (isInWhitelist) {
                uint256 availableToMintAmount = 5 - _preSaleMintedCount[minter];
                if (availableToMintAmount > 0) {
                    return (true, availableToMintAmount);
                }
            }
            return (false, 0);
        }
        return (false, 0);
    }

    function _checkUserEligibilityInPublicSale(address minter) internal view returns (bool, uint256) {
        if (isPublicSaleActive) {
            uint256 availableToMintAmount = 5 - _publicSaleMintedCount[minter];
            if (availableToMintAmount > 0) {
                return (true, availableToMintAmount);
            }
        }
        return (false, 0);
    }

    function _removeAddressFromFriendsWhitelist(address minter) internal {
        int index = -1;
        for (uint256 i = 0; i < _friendsSaleWhitelist.length; i += 1) {
            if (_friendsSaleWhitelist[i] == minter) {
                index = int(i);
                break;
            }
        }

        if (index != - 1) {
            delete _friendsSaleWhitelist[uint(index)];
        }
    }

    function _removeAddressFromPreSaleWhitelist(address minter) internal {
        int index = -1;
        for (uint256 i = 0; i < _preSaleWhitelist.length; i += 1) {
            if (_preSaleWhitelist[i] == minter) {
                index = int(i);
                break;
            }
        }

        if (index != - 1) {
            delete _preSaleWhitelist[uint(index)];
        }
    }

    function _removeAddressFromCharacterPassWhitelist(address minter) internal {
        int index = -1;
        for (uint256 i = 0; i < _characterPassWhitelist.length; i += 1) {
            if (_characterPassWhitelist[i] == minter) {
                index = int(i);
                break;
            }
        }

        if (index != - 1) {
            delete _characterPassWhitelist[uint(index)];
        }
    }

}