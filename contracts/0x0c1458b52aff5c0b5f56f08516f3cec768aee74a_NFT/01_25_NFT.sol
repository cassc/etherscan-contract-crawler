//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//  ===========================================================================================
//  #     #               ######
//  #     # ###### ###### #     #  ####  #    #  ####
//  #     # #      #      #     # #    # ##   # #    #
//  ####### #####  #####  #     # #    # # #  # #
//  #     # #      #      #     # #    # #  # # #  ###
//  #     # #      #      #     # #    # #   ## #    #
//  #     # ###### ###### ######   ####  #    #  ####
//
//  Welcome to the geeky side of HeeDong. There may or may not be an easter egg in this code.
//  If you find one, please let me know. I would love to hear from you.
//  ===========================================================================================

contract NFT is
    ERC721ABurnableUpgradeable,
    ERC721AQueryableUpgradeable,
    AccessControlUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    OwnableUpgradeable
{
    //  ============================================================
    //  Roles
    //  ============================================================
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public MAX_SUPPLY;

    string public prerevealedURI;
    string public baseURI;
    string public uriExtension;
    bool public isRevealed;
    bool public canTransferWhileStaked;

    mapping(uint256 => uint256) public tokenStakeStatus; // token id => timestamp
    address[] public blockedOperators;

    //  ============================================================
    //  Events
    //  ============================================================
    event Stake(uint256[] _tokenIds);
    event Unstake(uint256[] _tokenIds);

    //  ============================================================
    //  Initialisation
    //  ============================================================
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    // - `initializer` for OpenZeppelin's `OwnableUpgradeable`.
    function initialize() public initializerERC721A initializer {
        __ERC721A_init("HeeDong", "HD");
        __AccessControl_init();
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEV_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        MAX_SUPPLY = 5555;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            ERC721AUpgradeable,
            IERC721AUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setMaxSupply(uint256 _supply) external onlyRole(DEV_ROLE) {
        require(_supply > totalSupply(), "Cannot be > current supply");
        MAX_SUPPLY = _supply;
    }

    //  ============================================================
    //  Metadata Management
    //  ============================================================
    /// @dev starting token id
    /// @return starting token id
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setPrerevealedURI(
        string calldata _uri
    ) external onlyRole(DEV_ROLE) {
        prerevealedURI = _uri;
    }

    function setIsRevealed(bool _revealed) external onlyRole(DEV_ROLE) {
        isRevealed = _revealed;
    }

    function setBaseURI(string calldata _uri) external onlyRole(DEV_ROLE) {
        baseURI = _uri;
    }

    function setURIExtension(string calldata _ext) external onlyRole(DEV_ROLE) {
        uriExtension = _ext;
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721aMetadata: URI query for nonexistent token"
        );

        if (!isRevealed) return prerevealedURI;

        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(tokenId),
                    uriExtension
                )
            );
    }

    //  ============================================================
    //  Mint
    //  ============================================================
    /// @dev mint single token
    /// @param _quantities quantity of token to mint
    /// @param _delegateAddresses address to mint to
    function mint(
        uint256[] calldata _quantities,
        address[] calldata _delegateAddresses
    ) external payable onlyRole(MINTER_ROLE) {
        for (uint256 i; i < _delegateAddresses.length; i++) {
            _mint(_delegateAddresses[i], _quantities[i]);
        }
        require(_totalMinted() <= MAX_SUPPLY, "Exceed Total Supply");
    }

    //  ============================================================
    //  Burn
    //  ============================================================
    /// @dev burns a set of tokens
    /// @param _tokenIds array of token ids to burn
    function batchBurn(uint256[] calldata _tokenIds) external {
        for (uint256 i; i < _tokenIds.length; i++) {
            burn(_tokenIds[i]);
        }
    }

    //  ============================================================
    //  Staking
    //  ============================================================
    /// @param _tokenIds array of token ids to stake
    /// @param _stakedAt array of uint of the stakedAt time
    function updateStaking(
        uint256[] calldata _tokenIds,
        uint256[] calldata _stakedAt
    ) external onlyRole(DEV_ROLE) {
        for (uint256 i; i < _tokenIds.length; i++) {
            if (_stakedAt[i] > 0) {
                tokenStakeStatus[_tokenIds[i]] = _stakedAt[i];
            } else if (tokenStakeStatus[_tokenIds[i]] > 0) {
                delete tokenStakeStatus[_tokenIds[i]];
            }
        }
    }

    /// @dev stake a token
    /// @param _tokenIds array of token ids to stake
    function stake(uint256[] calldata _tokenIds) external {
        for (uint256 i; i < _tokenIds.length; i++) {
            require(ownerOf(_tokenIds[i]) == msg.sender, "Not Token Owner");

            // Prevents the token staking if it is already staked
            require(tokenStakeStatus[_tokenIds[i]] == 0, "Already Staked");

            tokenStakeStatus[_tokenIds[i]] = block.timestamp;
        }
        emit Stake(_tokenIds);
    }

    /// @dev get all token staked statuses
    function getAllStaked()
        external
        view
        onlyRole(DEV_ROLE)
        returns (uint256[] memory _stakedStatus)
    {
        uint256[] memory stakedStatuses = new uint256[](totalSupply() + 1);
        for (uint256 i; i <= totalSupply(); i++) {
            stakedStatuses[i] = tokenStakeStatus[i];
        }
        return stakedStatuses;
    }

    /// @dev get total stake count
    function getTotalStaked()
        external
        view
        onlyRole(DEV_ROLE)
        returns (uint256 _total)
    {
        uint256 total;
        for (uint256 i; i < totalSupply(); i++) {
            if (tokenStakeStatus[i] > 0) {
                total++;
            }
        }
        return total;
    }

    /// @dev get all token staked statuses
    /// @param _tokens array of tokens to check
    function getUsersStaked(
        uint256[] calldata _tokens
    ) external view returns (uint256[] memory _stakedStatus) {
        uint256[] memory stakedStatuses = new uint256[](_tokens.length);
        for (uint256 i; i < _tokens.length; i++) {
            address tokenOwner = ownerOf(_tokens[i]);
            require(
                tokenOwner == msg.sender || hasRole(DEV_ROLE, msg.sender),
                "Not Token Owner"
            );
            stakedStatuses[i] = tokenStakeStatus[_tokens[i]];
        }
        return stakedStatuses;
    }

    /// @dev unstake a token
    /// @param _tokenIds array of token ids to unstake
    function unstake(uint256[] calldata _tokenIds) external payable {
        for (uint256 i; i < _tokenIds.length; i++) {
            require(ownerOf(_tokenIds[i]) == msg.sender, "Not Token Owner");

            // Prevents the token staking if it is already staked
            require(tokenStakeStatus[_tokenIds[i]] > 0, "Not Staked");

            delete tokenStakeStatus[_tokenIds[i]];
        }
        emit Unstake(_tokenIds);
    }

    // ============================================================
    // Finance Management
    // ============================================================
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os, "Withdraw not successful");
    }

    // ============================================================
    // Transfer Functionality
    // ============================================================
    function setCanTransferWhileStaked(
        bool _canTransferWhileStaked
    ) public onlyRole(DEV_ROLE) {
        canTransferWhileStaked = _canTransferWhileStaked;
    }

    function transferWhileStaked(
        address to,
        uint256[] calldata tokenIds
    ) external {
        require(canTransferWhileStaked, "Transfer while staked not active");
        for (uint256 i; i < tokenIds.length; ) {
            super.transferFrom(msg.sender, to, tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }


    function isOperatorBlocked(address _operator) internal view returns (bool) {
        for (uint8 i; i < blockedOperators.length; i++) {
            if (blockedOperators[i] == _operator) {
                return true;
            }
        }
        return false;
    }

    /// @notice marketplaces operators to block; `setBlockedOperators` replaces the array, copy existing array to prevent deleting
    /// @dev implemented overriding to allow crud to be more efficient considering array size is small
    function setBlockedOperators(
        address[] calldata _blockedOperators
    ) public onlyRole(DEV_ROLE) {
        blockedOperators = _blockedOperators;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
        isNotStaked(tokenId)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
        isNotStaked(tokenId)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
        isNotStaked(tokenId)
    {
        super.transferFrom(from, to, tokenId);
    }

    modifier isNotStaked(uint256 _tokenId) {
        require(tokenStakeStatus[_tokenId] == 0, "Token is Staked");
        _;
    }

    modifier onlyAllowedOperator(address from) override {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    msg.sender
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
            if (isOperatorBlocked(from)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) override {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (
                !operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    operator
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
            if (isOperatorBlocked(operator)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }
}