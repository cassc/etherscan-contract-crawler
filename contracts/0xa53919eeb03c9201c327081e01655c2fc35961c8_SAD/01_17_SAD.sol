// SPDX-License-Identifier: MIT

//       _______  _______  ______             _
//      (  ____ \(  ___  )(  __  \           / )
//      | (    \/| (   ) || (  \  )      _  / /
//      | (_____ | (___) || |   ) |     (_)( (
//      (_____  )|  ___  || |   | |        | |
//            ) || (   ) || |   ) |      _ ( (
//      /\____) || )   ( || (__/  )     (_) \ \
//      \_______)|/     \|(______/           \_)

pragma solidity ^0.8.0;

import "ERC721.sol";
import "IERC721Receiver.sol";
import "Ownable.sol";
import "ERC721Enumerable.sol";
import "ERC721Royalty.sol";
import "ECDSA.sol";

/// @title SAD Society official contract
contract SAD is ERC721, IERC721Receiver, Ownable, ERC721Enumerable, ERC721Royalty {

    // ******************** //
    // *** GENERAL INFO *** //
    // ******************** //

    using ECDSA for bytes32;

    enum MintPhase {OFF, ALLOWLIST, PUBLIC}

    /// @dev How many tokens are left for breeding
    uint256 public availableForBreed = TOTAL_SADS - _RESERVE;

    /// @dev How many times a token has been staked for breeding and finished the process
    mapping(uint256 => uint256) public bredCount;

    /// @dev How many tokens have been bred
    uint256 public bred;

    uint256 public allowlistSupply;

    uint256 public allowlistMinted;

    address public allowlistSigner;

    string internal _baseURIInternal;

    MintPhase public currentMintPhase = MintPhase.OFF;

    /// @dev To prevent wallets from minting more than once
    mapping(address => bool) public hasMinted;

    mapping(uint256 => uint256) private _parents;

    string public constant PROVENANCE = "948c53a9e992089e7fda8770f18ffa4ae1f18bca1a4ae2c0871cc42f95608a07";

    uint256 public publicMinted;

    uint256 private constant _RESERVE = 20;

    address public royaltyAddress;

    uint256 private _sadFemaleMintIndex;

    uint256 private _sadMaleMintIndex;

    uint256 public constant SPEED_UP_PRICE_SEC = 34722222222;

    /// @dev Mapping of address to int array to keep track of what address has staked what tokens
    mapping(address => uint256[]) private _stakerToTokens;

    /// @dev Mapping to keep track of when each staker has staked 2 tokens to breed together
    mapping(uint256 => mapping(address => uint256)) private _stakeTimes;

    bool public stakingIsActive = false;

    uint256 public constant TOTAL_SADS = 7777;

    uint256 public constant TOTAL_SADS_FOR_MINT = 4444;

    /// @dev Enable ERC-721 token receiving for the staking process
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external view override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @dev Returns royalty price of a token for marketplaces supporting the EIP-2981 royalty standard.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * 750) / _feeDenominator();
        return (royaltyAddress, royaltyAmount);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, ERC721Enumerable, ERC721Royalty) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    // ******************** //
    // **** INITIALIZE **** //
    // ******************** //

    constructor() ERC721("SAD Society", "SAD") {}

    // ******************** //
    // **** CONDITIONS **** //
    // ******************** //

    function allowlistSaleActive() public view returns (bool) {
        return (currentMintPhase == MintPhase.ALLOWLIST || currentMintPhase == MintPhase.PUBLIC);
    }

    modifier isSignatureValid(bytes memory _signature, address _msgSender) {
        bytes32 messageHash = keccak256(abi.encodePacked(address(this), _msgSender));
        address signer = messageHash.toEthSignedMessageHash().recover(_signature);
        require(signer == allowlistSigner, "You are not in allowlist");
        _;
    }

    function publicSaleActive() public view returns (bool) {
        return currentMintPhase == MintPhase.PUBLIC;
    }

    // ******************** //
    // ***** ALLOWLIST **** //
    // ******************** //

    function allowlistMint(bytes memory _signature) public isSignatureValid(_signature, msg.sender) {
        require(allowlistSaleActive(), "Sale in not active");
        require(
            allowlistMinted + 1 <= allowlistSupply,
            "Purchase would exceed supply of allowlist tokens"
        );
        require(!hasMinted[msg.sender], "You have already minted your free SAD");

        allowlistMinted++;
        availableForBreed--;
        hasMinted[msg.sender] = true;
        _safeMintSad(msg.sender);
    }

    // ******************** //
    // **** PUBLIC SALE *** //
    // ******************** //

    function publicMint() public {
        require(publicSaleActive(), "Public sale in not active");
        require(
            TOTAL_SADS_FOR_MINT - allowlistSupply - publicMinted - 1 >= 0,
            "Purchase would exceed supply of public sale tokens"
        );
        require(!hasMinted[msg.sender], "You have already minted your free SAD");

        publicMinted++;
        availableForBreed--;
        hasMinted[msg.sender] = true;
        _safeMintSad(msg.sender);

    }

    // ******************** //
    // ***** BREEDING ***** //
    // ******************** //

    /// @dev Staker cancels breeding of 2 tokens and gets their tokens back
    function cancelStake(uint256 _tokenId1, uint256 _tokenId2) external {
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        require(_stakeTimes[concat][msg.sender] != 0, "Selected tokens are not staked or you are not the staker");
        _safeTransfer(address(this), msg.sender, _tokenId1, "");
        _safeTransfer(address(this), msg.sender, _tokenId2, "");
        delete _stakeTimes[concat][msg.sender];
        _removeTokenIdFromArray(_stakerToTokens[msg.sender], _tokenId1, _tokenId2);
        availableForBreed++;
    }

    /// @dev Checks conditions for breeding 2 tokens together. The conditions are as follows:
    ///      1. The supply for breeding a new token has not finished
    ///      2. The 2 tokens are of opposite sexes
    ///      3. Transaction sender is owner of both tokens
    ///      4. The 2 tokens are not related (siblings, half-siblings, parent or child of each other
    ///      If all requirements are met, returns how much time it takes for the breeding to complete and the price
    ///      to instantly finish the process
    function checkForBreed(uint256 _tokenId1, uint256 _tokenId2) public view returns (uint256 time, uint256 cost) {
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        uint256 parents1 = _parents[_tokenId1];
        uint256 parents2 = _parents[_tokenId2];
        require(availableForBreed > 0, "There are currently no more available tokens left. That might change if a staker cancels their stake");
        require(((_tokenId1 < 3889 && _tokenId2 >= 3889) || (_tokenId1 >= 3889 && _tokenId2 < 3889)), "You can only breed a male and a female SAD together");
        require(ownerOf(_tokenId1) == msg.sender && ownerOf(_tokenId2) == msg.sender, "You are not the owner of the requested tokens");
        if (!(parents1 / 10000 == 0 && parents2 / 10000 == 0)) {
            require(
                parents1 / 10000 != parents2 / 10000 &&
                parents1 % 10000 != parents2 % 10000 &&
                _tokenId1 != parents2 / 10000 &&
                _tokenId1 != parents2 % 10000 &&
                _tokenId2 != parents1 / 10000 &&
                _tokenId2 != parents1 % 10000,
                "You cannot breed siblings/half-siblings together or children with their parents"
            );
        }
        uint256 bredCount1 = bredCount[_tokenId1];
        uint256 bredCount2 = bredCount[_tokenId2];
        uint256 maxCount;
        if (bredCount1 > bredCount2) {
            maxCount = bredCount1;
        } else {
            maxCount = bredCount2;
        }
        uint256 breedTime = 200;
        for (uint256 i = 1; i < maxCount + 1; i++) {
            breedTime = breedTime * 161;
        }
        breedTime = breedTime / (100 ** (maxCount + 1));
        breedTime = breedTime * (1 weeks);
        uint256 price = breedTime * SPEED_UP_PRICE_SEC;
        return (breedTime, price);
    }

    function claimBreed(uint256 _tokenId1, uint256 _tokenId2) external {
        bool senderIsStaker = false;
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        for (uint256 i = 0; i < _stakerToTokens[msg.sender].length; i++) {
            if (_stakerToTokens[msg.sender][i] == concat) {
                senderIsStaker = true;
                break;
            }
        }
        require(senderIsStaker, "Selected tokens are not staked or you are not the staker");
        require(getRemainingBreedTime(_tokenId1, _tokenId2) == 0, "Breed time has not finished yet");
        _safeTransfer(address(this), msg.sender, _tokenId1, "");
        _safeTransfer(address(this), msg.sender, _tokenId2, "");
        uint256 bredToken = _safeMintSad(msg.sender);
        bred++;
        bredCount[_tokenId1]++;
        bredCount[_tokenId2]++;
        _parents[bredToken] = concat;
        delete _stakeTimes[concat][msg.sender];
        _removeTokenIdFromArray(_stakerToTokens[msg.sender], _tokenId1, _tokenId2);
    }

    /// @dev Returns token IDs for the parents of a selected token. Returns 0 for both if selected token is Gen0
    function getParents(uint256 _tokenId) public view returns (uint256, uint256) {
        uint256 parents_ = _parents[_tokenId];
        uint256 mother = parents_ / 10000;
        uint256 father = parents_ % 10000;
        return (mother, father);
    }

    /// @dev Returns the currently remaining time in seconds for the breeding process of 2 tokens to finish,
    ///      returns 0 if the process has completed
    function getRemainingBreedTime(uint256 _tokenId1, uint256 _tokenId2) public view returns (uint256) {
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        require(_stakeTimes[concat][msg.sender] != 0, "Selected tokens are not staked or you are not the staker");
        uint256 bredCount1 = bredCount[_tokenId1];
        uint256 bredCount2 = bredCount[_tokenId2];
        uint256 maxCount;
        if (bredCount1 > bredCount2) {
            maxCount = bredCount1;
        } else {
            maxCount = bredCount2;
        }
        uint256 breedTime = 200;
        for (uint256 i = 1; i < maxCount + 1; i++) {
            breedTime = breedTime * 161;
        }
        breedTime = breedTime / (100 ** (maxCount + 1));
        breedTime = breedTime * (1 weeks);
        uint256 stakedAt = _stakeTimes[concat][msg.sender];
        uint256 dueTime = stakedAt + breedTime;
        if (dueTime > block.timestamp) {
            return dueTime - block.timestamp;
        } else {
            return 0;
        }
    }

    /// @dev Get the current cost of instantly finishing the breeding process of 2 tokens
    function getSpeedUpPrice(uint256 _tokenId1, uint256 _tokenId2) public view returns (uint256) {
        uint256 remainingTime = getRemainingBreedTime(_tokenId1, _tokenId2);
        uint256 price = remainingTime * SPEED_UP_PRICE_SEC;
        return price;
    }

    /// @dev Returns token IDs of tokens a wallet address has staked for breeding
    function getStakedTokens() public view returns (uint256[] memory) {
        uint256 stakedCount = _stakerToTokens[msg.sender].length;
        uint256[] memory stakedTokens = new uint256[](stakedCount * 2);
        for (uint256 i = 0; i < stakedCount; i++) {
            stakedTokens[i * 2] = (_stakerToTokens[msg.sender][i] / 10000);
            stakedTokens[(i * 2) + 1] = (_stakerToTokens[msg.sender][i] % 10000);
        }
        return stakedTokens;
    }

    /// @dev Instantly completes the breeding process at a cost determined by the remaining breeding time.
    function instantBreed(uint256 _tokenId1, uint256 _tokenId2) public payable {
        bool senderIsStaker = false;
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        for (uint256 i = 0; i < _stakerToTokens[msg.sender].length; i++) {
            if (_stakerToTokens[msg.sender][i] == concat) {
                senderIsStaker = true;
                break;
            }
        }
        require(senderIsStaker, "Selected tokens are not staked or you are not the staker");
        uint256 price = getSpeedUpPrice(_tokenId1, _tokenId2);
        require(msg.value >= price, "Ether value sent is not correct");
        _safeTransfer(address(this), msg.sender, _tokenId1, "");
        _safeTransfer(address(this), msg.sender, _tokenId2, "");
        uint256 bredToken = _safeMintSad(msg.sender);
        bred++;
        bredCount[_tokenId1]++;
        bredCount[_tokenId2]++;
        _parents[bredToken] = concat;
        delete _stakeTimes[concat][msg.sender];
        _removeTokenIdFromArray(_stakerToTokens[msg.sender], _tokenId1, _tokenId2);
    }

    /// @dev Stake 2 tokens to breed together
    function stakeForBreed(uint256 _tokenId1, uint256 _tokenId2) external {
        require(stakingIsActive, "Staking is not active");
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        uint256 parents1 = _parents[_tokenId1];
        uint256 parents2 = _parents[_tokenId2];
        require(availableForBreed > 0, "There are currently no more available tokens left. That might change if a staker cancels their stake");
        require(((_tokenId1 < 3889 && _tokenId2 >= 3889) || (_tokenId1 >= 3889 && _tokenId2 < 3889)), "You can only breed a male and a female SAD together");
        require(ownerOf(_tokenId1) == msg.sender && ownerOf(_tokenId2) == msg.sender, "You are not the owner of the requested tokens");
        if (!(parents1 / 10000 == 0 && parents2 / 10000 == 0)) {
            require(
                parents1 / 10000 != parents2 / 10000 &&
                parents1 % 10000 != parents2 % 10000 &&
                _tokenId1 != parents2 / 10000 &&
                _tokenId1 != parents2 % 10000 &&
                _tokenId2 != parents1 / 10000 &&
                _tokenId2 != parents1 % 10000,
                "You cannot breed siblings/half-siblings together or children with their parents"
            );
        }
        _safeTransfer(msg.sender, address(this), _tokenId1, "");
        _safeTransfer(msg.sender, address(this), _tokenId2, "");
        _stakeTimes[concat][msg.sender] = block.timestamp;
        _stakerToTokens[msg.sender].push(concat);
        availableForBreed--;
    }

    // ******************** //
    // ***** CLAIMING ***** //
    // ******************** //

    address public badContractAddress;

    function burnSads(uint256[5] memory _tokenIdList)
    external returns (bool) {
        require(msg.sender == badContractAddress, "Sender is not BAD contract");
        _burn(_tokenIdList[0]);
        _burn(_tokenIdList[1]);
        _burn(_tokenIdList[2]);
        _burn(_tokenIdList[3]);
        _burn(_tokenIdList[4]);
        return true;
    }

    // ******************** //
    // ******* ADMIN ****** //
    // ******************** //

    function flipStakeState() public onlyOwner {
        stakingIsActive = !stakingIsActive;
    }

    /// @dev Mint the reserved tokens to contract owner
    function reserveSads() public onlyOwner {
        for (uint256 i = 0; i < _RESERVE / 2; i++) {
            _safeMint(msg.sender, i);
            _safeMint(msg.sender, (TOTAL_SADS / 2) + 1 + i);
        }
    }

    function setAllowlistSigner(address _address) public onlyOwner {
        allowlistSigner = _address;
    }

    function setAllowlistSupply(uint256 _supply) public onlyOwner {
        allowlistSupply = _supply;
    }

    function setBadContractAddress(address _address) public onlyOwner {
        badContractAddress = _address;
    }

    function setBaseURI(string memory _baseURIToSet) public onlyOwner {
        _baseURIInternal = _baseURIToSet;
    }

    function setMintPhase(MintPhase phase) public onlyOwner {
        currentMintPhase = phase;
    }

    function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // ******************** //
    // ****** UTILITY ***** //
    // ******************** //

    function _baseURI() internal view override returns (string memory) {
        return _baseURIInternal;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function _burn(uint256 _tokenId) internal virtual override(ERC721, ERC721Royalty) {
        super._burn(_tokenId);
        _resetTokenRoyalty(_tokenId);
    }

    function _removeTokenIdFromArray(uint256[] storage _array, uint256 _tokenId1, uint256 _tokenId2) internal {
        uint256 concat;
        if (_tokenId1 > _tokenId2) {
            concat = _tokenId1 * 10000 + _tokenId2;
        } else {
            concat = _tokenId2 * 10000 + _tokenId1;
        }
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; i++) {
            if (_array[i] == concat) {
                length--;
                if (i < length) {
                    _array[i] = _array[length];
                }
                _array.pop();
                break;
            }
        }
    }

    function _safeMintSad(address _to) internal returns (uint256) {
        uint8 randomNumber = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        _sadMaleMintIndex + _sadFemaleMintIndex
                    )
                )
            ) % 2
        );
        if (randomNumber == 0) {
            if (_sadMaleMintIndex < TOTAL_SADS / 2 - _RESERVE / 2 + 1) {
                _safeMint(_to, _sadMaleMintIndex + _RESERVE / 2);
                _sadMaleMintIndex = _sadMaleMintIndex + 1;
                return _sadMaleMintIndex + _RESERVE / 2 - 1;

            } else {
                _safeMint(
                    _to,
                    _sadFemaleMintIndex + 1 + TOTAL_SADS / 2 + _RESERVE / 2
                );
                _sadFemaleMintIndex = _sadFemaleMintIndex + 1;
                return _sadFemaleMintIndex + 1 + TOTAL_SADS / 2 + _RESERVE / 2 - 1;
            }
        } else {
            if (_sadFemaleMintIndex < TOTAL_SADS / 2 - _RESERVE / 2) {
                _safeMint(
                    _to,
                    _sadFemaleMintIndex + 1 + TOTAL_SADS / 2 + _RESERVE / 2
                );
                _sadFemaleMintIndex = _sadFemaleMintIndex + 1;
                return _sadFemaleMintIndex + 1 + TOTAL_SADS / 2 + _RESERVE / 2 - 1;
            } else {
                _safeMint(_to, _sadMaleMintIndex + _RESERVE / 2);
                _sadMaleMintIndex = _sadMaleMintIndex + 1;
                return _sadMaleMintIndex + _RESERVE / 2 - 1;
            }
        }
    }
}