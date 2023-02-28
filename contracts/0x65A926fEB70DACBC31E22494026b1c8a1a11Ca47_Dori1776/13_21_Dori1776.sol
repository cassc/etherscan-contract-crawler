// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface IDoriStaking {
    function getStakedTokens(address _owner, address _contract)
        external
        view
        returns (uint256[] memory);
}

contract Dori1776 is
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    struct Stake {
        address owner; // 32bits
        uint128 timestamp; // 32bits
    }

    struct Burn {
        address owner; // 32bits
        uint128 timestamp; // 32bits
    }

    mapping(address => bool) public whitelistClaimed;
    mapping(address => bool) public publicMinted;
    mapping(uint256 => bool) public tokenClaimed;
    mapping(uint256 => bool) public lockStatus;
    mapping(uint256 => uint256) public lockData;
    mapping(uint256 => uint256) public burnData;
    mapping(address => uint256) public burnRewards;
    mapping(address => uint256[]) public userLockedTokens;
    mapping(address => uint256[]) public userBurnTokens;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri =
        "ipfs://Qme972jB82AfDPuXExo77ZUabkH2ijX8binp7HvP777Umy/hidden.json";

    uint256 public cost;
    uint256 public maxSupply = 1776;
    uint256 public maxMintSupply = 888;
    uint256 public maxMintAmountPerTx = 1;
    uint256 public lockReward = 1;
    address public doriGenesis = 0x6d9c17bc83a416bB992ccc671BEbd98d7A76cfc3;
    address public doriStaking = 0x832EA9dAdf3BA29aAFf64E82f5c48C149920862F;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public claimEnabled = false;
    bool public burnEnabled = false;
    bool public revealed = false;
    bool public lockingAllowed;
    bytes32 public merkleRoot;

    event Lock(uint256 token, uint256 timeStamp, address user);
    event Unlock(uint256 token, uint256 timeStamp, address user);
    event BurnToken(uint256 token, uint256 timeStamp, address user);

    constructor() ERC721A("Dori1776", "DORI1776") {}

    /*
    ================================================
                    Modifiers        
    ================================================
    */

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxMintSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    /*
    ================================================
                    Mint Functions        
    ================================================
    */

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        require(!publicMinted[_msgSender()], "Address already minted!");
        publicMinted[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function claim(uint256[] calldata _tokenIds) public {
        require(claimEnabled, "Claim is not enabled!");

        uint256[] memory stakedTokens = IDoriStaking(doriStaking)
            .getStakedTokens(_msgSender(), doriGenesis);
        require(stakedTokens.length > 0, "No staked tokens found!");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] <= 888, "Token ID is not eligible for claim!");
            require(!tokenClaimed[_tokenIds[i]], "Token already claimed!");

            bool found = false;
            for (uint256 j = 0; j < stakedTokens.length; j++) {
                if (stakedTokens[j] == _tokenIds[i]) {
                    found = true;
                    break;
                }
            }
            require(found, "Token not found in staked tokens!");
            // mark the token as claimed
            tokenClaimed[_tokenIds[i]] = true;
        }

        _safeMint(_msgSender(), _tokenIds.length);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    /*
    ================================================
            Locking and Rewards Functions      
    ================================================
    */

    function lockTokens(uint256[] calldata tokenIds) external nonReentrant {
        require(lockingAllowed, "Locking is not currently allowed.");
        for (uint256 i; i < tokenIds.length; i++) {
            _lockToken(tokenIds[i]);
        }
    }

    function unlockTokens(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            _unlockToken(tokenIds[i]);
        }
    }

    /*
    ================================================
                    Burn Functions      
    ================================================
    */

    function burn(uint256[] calldata tokenIds) external {
        require(burnEnabled, "Burn is not enabled!");
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                ownerOf(tokenIds[i]) == msg.sender,
                "You must own a token in order to unlock it"
            );
            if (lockStatus[tokenIds[i]] == true) {
                _unlockToken(tokenIds[i]);
            }

            uint256 burnReward = _calculateReward(tokenIds[i]);
            burnRewards[msg.sender] += burnReward;
            userBurnTokens[msg.sender].push(tokenIds[i]);
            burnData[tokenIds[i]] = block.timestamp;
            Dori1776.transferFrom(msg.sender, burnAddress, tokenIds[i]);
            emit BurnToken(tokenIds[i], block.timestamp, msg.sender);
        }
    }

    /*
    ================================================
                Setters and Getters       
    ================================================
    */

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721Metadata)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function toggleLocking() external onlyOwner {
        lockingAllowed = !lockingAllowed;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function setBurnEnabled(bool _state) public onlyOwner {
        burnEnabled = _state;
    }

    function setLockReward(uint256 _lockReward) public onlyOwner {
        lockReward = _lockReward;
    }

    function setClaimEnabled(bool _state) public onlyOwner {
        claimEnabled = _state;
    }

    function setDoriGenesis(address _doriGenesis) public onlyOwner {
        doriGenesis = _doriGenesis;
    }

    function setDoriStaking(address _doriStaking) public onlyOwner {
        doriStaking = _doriStaking;
    }

    function balanceOfBurned(address _user) public view returns (uint256) {
        return userBurnTokens[_user].length;
    }

    function getRewards(address _user) public view returns (uint256) {
        uint256 reward = 0;
        for (uint256 i = 0; i < userLockedTokens[_user].length; i++) {
            reward += _calculateReward(userLockedTokens[_user][i]);
        }
        return reward + burnRewards[_user];
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    /*
    ================================================
                    Owner Functions        
    ================================================
    */
    function unlockTokensOwner(uint256[] calldata tokens) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            _unlockToken(tokens[i]);
        }
    }

    function lockTokensOwner(uint256[] calldata tokens) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            _lockToken(tokens[i]);
        }
    }

    /*
    ================================================
                Internal Write Functions         
    ================================================
    */

    function _lockToken(uint256 tokenId) internal {
        require(
            ownerOf(tokenId) == msg.sender || owner() == msg.sender,
            "You must own a token in order to unlock it"
        );
        require(lockStatus[tokenId] == false, "token already locked");
        lockStatus[tokenId] = true;
        lockData[tokenId] = block.timestamp;
        userLockedTokens[msg.sender].push(tokenId);
        emit Lock(tokenId, block.timestamp, ownerOf(tokenId));
    }

    function _unlockToken(uint256 tokenId) internal {
        require(
            ownerOf(tokenId) == msg.sender || owner() == msg.sender,
            "You must own a token in order to unlock it"
        );
        require(lockStatus[tokenId] == true, "token not locked");
        lockStatus[tokenId] = false;
        lockData[tokenId] = 0;

        uint256[] storage userLockedTokensArray = userLockedTokens[msg.sender];
        for (uint256 i; i < userLockedTokensArray.length; i++) {
            if (userLockedTokensArray[i] == tokenId) {
                userLockedTokensArray[i] = userLockedTokensArray[
                    userLockedTokensArray.length - 1
                ];
                userLockedTokensArray.pop();
                break;
            }
        }
        emit Unlock(tokenId, block.timestamp, ownerOf(tokenId));
    }

    function _calculateReward(uint256 _tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 timeSinceStake = block.timestamp - lockData[_tokenId];
        uint256 reward = timeSinceStake * lockReward * 1e18;
        return reward / 86400;
    }

    /*
    ================================================
                Transfer Override        
    ================================================
    */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        bool lock = false;
        for (uint256 i; i < quantity; i++) {
            if (lockStatus[startTokenId + i] == true) {
                lock = true;
            }
        }
        require(lock == false, "Token Locked");
    }

    /*
    ================================================
                Royalities Override         
    ================================================
    */

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}