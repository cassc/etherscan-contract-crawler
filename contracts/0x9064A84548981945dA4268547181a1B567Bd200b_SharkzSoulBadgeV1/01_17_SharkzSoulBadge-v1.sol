// SPDX-License-Identifier: MIT

/**
       █                                                                        
▐█████▄█ ▀████ █████  ▐████    ████████    ███████████  ████▌  ▄████ ███████████
▐██████ █▄ ▀██ █████  ▐████   ██████████   ████   ████▌ ████▌ ████▀       ████▀ 
  ▀████ ███▄ ▀ █████▄▄▐████  ████ ▐██████  ████▄▄▄████  █████████        ████▀  
▐▄  ▀██ █████▄ █████▀▀▐████ ▄████   ██████ █████████    █████████      ▄████    
▐██▄  █ ██████ █████  ▐█████████▀    ▐█████████ ▀████▄  █████ ▀███▄   █████     
▐████  █▀█████ █████  ▐████████▀        ███████   █████ █████   ████ ███████████
       █
 *******************************************************************************
 * Sharkz Soul Badge
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../lib/sharkz/IScore.sol";
import "../lib-upgradeable/sharkz/AdminableUpgradeable.sol";
import "../lib-upgradeable/5114/ERC5114SoulBadgeUpgradeable.sol";
import "../lib-upgradeable/712/EIP712WhitelistUpgradeable.sol";

interface IBalanceOf {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IVoter {
    // Get voter vote value for a poll
    function getAddressVote(uint256 _pid, address _addr) external view returns (uint256);
}

contract SharkzSoulBadgeV1 is IScore, Initializable, UUPSUpgradeable, AdminableUpgradeable, ReentrancyGuardUpgradeable, EIP712WhitelistUpgradeable, ERC5114SoulBadgeUpgradeable {
    // Implementation version number
    function version() external pure virtual returns (string memory) { return "1.1"; }

    struct MintConfig {
        // Mint modes, 0: disable-minting, 1: free-mint, 2: restrict minting to target token owner, 3: restrict to voter
        uint8 mintMode;
        // Max mint supply, max 65535
        uint16 mintSupply;
        // Start time of minting
        uint40 mintStartTime;
        // End time of minting
        uint40 mintEndTime;
        // How many badges can be minted from a `Soul`, zero means unlimited
        uint8 maxMintPerSoul;

        // Keep track of total minted token count, max 2^128 - 1
        uint128 tokenMinted;
    }
    MintConfig public mintConfig;
    
    // Target token contract for limited minting
    address public tokenContract;

    // Target voting contract for limited minting
    address public voteContract;

    // Target voting poll Id for limited minting
    uint256 public votePollId;

    // Minting by claim contract
    address internal _claimContract;

    // Token image (all token use same image)
    string public tokenImageUri;

    // Init this upgradeable contract
    function initialize(string memory _name, string memory _symbol, string memory _collectionUri, string memory _tokenImageUri) public initializer onlyProxy {
        __Adminable_init();
        __ReentrancyGuard_init();
        __EIP712Whitelist_init();
        __ERC5114SoulBadge_init(_name, _symbol, _collectionUri, "");
        // token image is a immuntable fixed uri for all tokens
        tokenImageUri = _tokenImageUri;
        // default mint supply 10k
        mintConfig.mintSupply = 10000;
        // by default, one Soul can only mint 1 badge
        mintConfig.maxMintPerSoul = 1;
    }

    // only admins can upgrade the contract
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /**
     * @dev {IERC5114-tokenUri} alias to tokenURI(), so we just override tokenURI()
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Non-existent token");

        string memory output = string(abi.encodePacked(
          '{"name":"', name, ' #', _toString(tokenId), '","image":"', tokenImageUri, '"}'
        ));
        return string(abi.encodePacked("data:application/json;utf8,", output));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || 
               interfaceId == type(IScore).interfaceId;
    }

    /**
     * @dev See {IScore-baseScore}.
     */
    function baseScore() public pure virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IScore-scoreByToken}.
     */
    function scoreByToken(uint256 _tokenId) external view virtual override returns (uint256) {
        if (_exists(_tokenId)) {
          return 1;
        } else {
          return 0;
        }
    }

    /**
     * @dev See {IScore-scoreByAddress}.
     */
    function scoreByAddress(address _addr) external view virtual override returns (uint256) {
        require(_addr != address(0), "Address is the zero address");
        revert("score by address not supported");
    }

    // Caller must not be an wallet account
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller should not be a contract");
        _;
    }

    // Caller must be `Soul` token owner
    modifier callerIsSoulOwner(address soulContract, uint256 soulTokenId) {
        require(soulContract != address(0), "Soul contract is the zero address");
        require(msg.sender == _getSoulOwnerAddress(soulContract, soulTokenId), "Caller is not Soul token owner");
        _;
    }

    // Change mint settings
    function setMintConfig(uint8 _mode, uint16 _mintSupply, uint40 _startTime, uint40 _endTime, uint8 _maxPerSoul) external virtual onlyAdmin {
        mintConfig.mintMode = _mode;
        mintConfig.mintSupply = _mintSupply;
        mintConfig.mintStartTime = _startTime;
        mintConfig.mintEndTime = _endTime;
        mintConfig.maxMintPerSoul = _maxPerSoul;
    }

    // Update linking IBalanceOf contract address
    function setMintRestrictContract(address _addr) external onlyAdmin {
        tokenContract = _addr;
    }

    // Update linking vote contract and poll Id
    function setMintRestrictVote(address _addr, uint256 _pid) external onlyAdmin {
        voteContract = _addr;
        votePollId = _pid;
    }

    // Update linking claim contract
    function setClaimContract(address _addr) external onlyAdmin {
        _claimContract = _addr;
    }

    // Returns total valid token count
    function totalSupply() public view returns (uint256) {
        return mintConfig.tokenMinted;
    }

    // Create a new token for Soul
    function _runMint(address soulContract, uint256 soulTokenId, bool skipModeCheck) 
        private 
        nonReentrant 
        onlyProxy
    {
        MintConfig memory config = mintConfig;
        require(config.mintMode > 0 || skipModeCheck, 'Minting disabled');
        require(config.tokenMinted < config.mintSupply, 'Max minting supply reached');
        require(config.maxMintPerSoul == 0 || _soulData[soulContract][soulTokenId] < config.maxMintPerSoul, "Max minting per soul reached");
        uint256 time = block.timestamp;
        require(config.mintStartTime == 0 || time >= config.mintStartTime, "Minting is not started");
        require(config.mintEndTime == 0 || time < config.mintEndTime, "Minting ended");

        // mint badge to the Soul (Soul contract, Soul tokenId), start from #0
        _mint(mintConfig.tokenMinted, soulContract, soulTokenId);
        unchecked {
          mintConfig.tokenMinted += 1;
        }
    }

    // Minting by admin to any address
    function ownerMint(address soulContract, uint256 soulTokenId) 
        external 
        onlyAdmin 
    {
        _runMint(soulContract, soulTokenId, true);
    }

    // Minting from claim contract
    function claimMint(address soulContract, uint256 soulTokenId) external {
        require(_claimContract != address(0), "Linked claim contract is not set");
        require(_claimContract == msg.sender, "Caller is not claim contract");
        _runMint(soulContract, soulTokenId, false);
    }

    // Public minting, limited to Soul Token owner
    function publicMint(address soulContract, uint256 soulTokenId) 
        external 
        callerIsUser() 
        callerIsSoulOwner(soulContract, soulTokenId)
    {
        if (mintConfig.mintMode == 2) {
            // target token owner
            require(tokenContract != address(0), "Token contract is the zero address");
            require(_isExternalTokenOwner(tokenContract, msg.sender), "Caller is not target token owner");
        }
        if (mintConfig.mintMode == 3) {
            // target poll voter
            require(voteContract != address(0), "Vote contract is the zero address");
            require(isVoter(voteContract, votePollId, msg.sender), "Caller is not voter");
        }
        _runMint(soulContract, soulTokenId, false);
    }

    // Minting with signature from contract EIP712 signer, limited to Soul Token owner
    function whitelistMint(bytes calldata _signature, address soulContract, uint256 soulTokenId) 
        external 
        checkWhitelist(_signature) 
        callerIsUser 
        callerIsSoulOwner(soulContract, soulTokenId)
    {
        _runMint(soulContract, soulTokenId, false);
    }

    /**
     * @dev Returns whether an address is NFT owner
     */
    function _isExternalTokenOwner(address _contract, address _ownerAddress) internal view returns (bool) {
        try IBalanceOf(_contract).balanceOf(_ownerAddress) returns (uint256 balance) {
            return balance > 0;
        } catch (bytes memory) {
          // when reverted, just returns...
          return false;
        }
    }

    /**
     * @dev Returns whether an address is a voter for a poll
     */
    function isVoter(address _contract, uint256 _pid, address _addr) public view returns (bool) {
        try IVoter(_contract).getAddressVote(_pid, _addr) returns (uint256 voteOption) {
            return voteOption > 0;
        } catch (bytes memory) {
          // when reverted, just returns...
          return false;
        }
    }
}