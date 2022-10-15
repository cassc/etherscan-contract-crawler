// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721P.sol";

contract XeniaLand is ERC721P, Ownable {
    using ECDSA for bytes32;

    address public signer = 0x69d1233747A6Cdde4ba700799954ecB3b8A48340;

    string private baseTokenURI;
    string public provenance;

    uint256 public maxSupply = 3136;
    uint256 public reserved = 56;

    uint256 public wlLandPrice = 0.1875 ether;
    uint256 public landPrice = 0.225 ether;

    mapping(address => bool) public wlLandMints;
    mapping(address => uint256) public landMints;

    bool public publicSaleIsActive = false;
    bool public allowSaleIsActive = false;

    uint256 public landMax = 2;

    constructor() ERC721P("Xenia Land", "XLAND") {}

    function allowMint(
        bool _startStaking,
        bytes memory _signature
    ) external payable {
        require(allowSaleIsActive, "Not active");
        require(remaining() > 0, "Max land supply reached");
        require(msg.value == wlLandPrice, "Wrong amount sent");
        require(!wlLandMints[msg.sender],"Already minted");
        require(msg.sender == tx.origin, "bm8gcm9ib3Rz");

        bytes32 hash = hashTransaction(_msgSender());
        require(
            matchSignerAdmin(signTransaction(hash), _signature),
            "Signature mismatch"
        );

        wlLandMints[msg.sender] = true;
        mint(1, msg.sender, _startStaking);
    }

    function saleMint(uint256 _amount, bool _startStaking) external payable {
        require(publicSaleIsActive, "Not active");
        require(_amount <= remaining(), "Max land supply reached");
        require(msg.value == _amount * landPrice, "Wrong amount sent");
        require(
            landMints[msg.sender] + _amount <= landMax,
            "Exceeds allowance"
        );
        require(msg.sender == tx.origin, "bm8gcm9ib3Rz");

        unchecked {
            landMints[msg.sender] += _amount;
        }
        mint(_amount, msg.sender, _startStaking);
    }

    function ownerMint(
        address _recepient,
        uint256 _amount,
        bool _startStaking
    ) external onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");
        require(_amount <= reserved, "Amount exceeds reserve");
        unchecked {
            reserved -= _amount;
        }

        mint(_amount, _recepient, _startStaking);
    }

    function mint(
        uint256 _amount,
        address _recepient,
        bool _startStaking
    ) internal {
        for (uint256 i; i < _amount; ) {
            _safeMint(_recepient);
            if (_startStaking) {
                _stake(uint16(totalSupply()));
            }
            unchecked {
                ++i;
            }
        }
    }

    function stake(uint16[] memory _tokenIds) external {
        for (uint256 i; i < _tokenIds.length; ) {
            require(
                ownerOf(_tokenIds[i]) == msg.sender,
                "Not owned or already staked"
            );
            _stake(_tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function stakeAll() external {
        uint16[] memory tokensOwned = tokensOfOwner(msg.sender);
        for (uint256 i; i < tokensOwned.length; ) {
            if (ownerOf(tokensOwned[i]) == msg.sender) {
                _stake(tokensOwned[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function unstake(uint16[] memory _tokenIds) external {
        require(isTrueOwnerOfTokens(msg.sender, _tokenIds), "Not owned");
        for (uint256 i; i < _tokenIds.length; ) {
            require(isTokenStaked(_tokenIds[i]), "Not staked");
            _unstake(msg.sender, _tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function unstakeAll() external {
        uint16[] memory tokensOwned = tokensOfOwner(msg.sender);
        for (uint256 i; i < tokensOwned.length; ) {
            if (ownerOf(tokensOwned[i]) != msg.sender) {
                _unstake(msg.sender, tokensOwned[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    // internal

    function _stake(uint16 _tokenId) internal {
        address real_owner = _owners[_tokenId];
        _owners[_tokenId] = address(this);
        emit Transfer(real_owner, address(this), _tokenId);
    }

    function _unstake(address _realOwner, uint16 _tokenId) internal {
        _owners[_tokenId] = _realOwner;
        emit Transfer(address(this), _realOwner, _tokenId);
    }

    // getters

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function isTokenStaked(uint16 _tokenId) public view returns (bool) {
        return ownerOf(_tokenId) == address(this);
    }

    // returns number of tokens staked by user
    function stakedNumberByOwner(address _user)
        public
        view
        returns (uint16 stakedCount)
    {
        uint16[] memory tokensOwned = tokensOfOwner(_user);
        for (uint256 i; i < tokensOwned.length; ) {
            if (isTokenStaked(tokensOwned[i])) {
                ++stakedCount;
            }
            unchecked {
                ++i;
            }
        }
    }

    function unstakedNumberByOwner(address _user)
        public
        view
        returns (uint16 unstakedCount)
    {
        uint16[] memory tokensOwned = tokensOfOwner(_user);
        for (uint256 i; i < tokensOwned.length; ) {
            if (!isTokenStaked(tokensOwned[i])) {
                ++unstakedCount;
            }
            unchecked {
                ++i;
            }
        }
    }

    // returns array of tokenIds staked by user
    function stakedIdsByOwner(address _user)
        external
        view
        returns (uint16[] memory)
    {
        uint16[] memory tokensOwned = tokensOfOwner(_user);
        uint256 stakedCount = stakedNumberByOwner(_user);
        uint16[] memory tokensStaked = new uint16[](stakedCount);
        uint256 idx;
        for (uint256 i; i < tokensOwned.length; ) {
            if (isTokenStaked(tokensOwned[i])) {
                tokensStaked[idx] = tokensOwned[i];
                ++idx;
            }
            unchecked {
                ++i;
            }
        }
        return tokensStaked;
    }

    function unstakedIdsByOwner(address _user)
        external
        view
        returns (uint16[] memory)
    {
        uint16[] memory tokensOwned = tokensOfOwner(_user);
        uint256 unstakedCount = unstakedNumberByOwner(_user);
        uint16[] memory tokensUnstaked = new uint16[](unstakedCount);
        uint256 idx;
        for (uint256 i; i < tokensOwned.length; ) {
            if (!isTokenStaked(tokensOwned[i])) {
                tokensUnstaked[idx] = tokensOwned[i];
                ++idx;
            }
            unchecked {
                ++i;
            }
        }
        return tokensUnstaked;
    }

    function isTrueOwnerOfTokens(address _user, uint16[] memory _tokenIds)
        public
        view
        returns (bool)
    {
        bool found;
        uint16[] memory tokensOwned = tokensOfOwner(_user);
        for (uint256 i; i < _tokenIds.length; ) {
            found = false;
            for (uint256 j; j < tokensOwned.length; ) {
                if (_tokenIds[i] == tokensOwned[j]) {
                    found = true;
                    break;
                }
                unchecked {
                    ++j;
                }
            }
            if (!found) return false;
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function remaining() public view returns (uint256 nftsRemaining) {
        unchecked {
            nftsRemaining = maxSupply - totalSupply() - reserved;
        }
    }

    // Owner setters

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function setSigner(address _newSigner) external onlyOwner {
        signer = _newSigner;
    }

    function setMaxLandPerWallet(uint256 _max) external onlyOwner {
        landMax = _max;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
    }

    function toggleAllowSale() external onlyOwner {
        allowSaleIsActive = !allowSaleIsActive;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        landPrice = _newPrice;
    }

    function setWlPrice(uint256 _newPrice) external onlyOwner {
        wlLandPrice = _newPrice;
    }

    function setBaseURI(string calldata _newBaseTokenURI) external onlyOwner {
        baseTokenURI = _newBaseTokenURI;
    }

    function setProvenanceHash(string memory provenanceHash)
        external
        onlyOwner
    {
        provenance = provenanceHash;
    }

    function hashTransaction(address _sender)
        public
        pure
        returns (bytes32 _hash)
    {
        _hash = keccak256(abi.encode(_sender));
    }

    function signTransaction(bytes32 _hash) public pure returns (bytes32) {
        return _hash.toEthSignedMessageHash();
    }

    function matchSignerAdmin(bytes32 _payload, bytes memory _signature)
        public
        view
        returns (bool)
    {
        return signer == _payload.recover(_signature);
    }
}