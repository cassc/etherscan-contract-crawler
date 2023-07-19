// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

/// @title IQZoneNFT
/// @author gotbit
contract IQZoneNFT is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER');
    bytes32 public constant INTERNAL_MINTER_ROLE = keccak256('INTERNAL_MINTER');

    struct Property {
        bool mintable;
        bool singleton;
        bool transferable;
        uint256 minAllocationSize; // in USD with 2 decimal points of precision
        uint256 maxAllocationSize; // in USD with 2 decimal points of precision
        bool[3] allowedRounds;
        uint256 maxSupply;
        uint256 price;
        bool buybackGarantee;
        bool burnOnBuy;
        address token; // token the nft is bought with
    }

    uint256 public idCounter = 0;
    uint256 public nftChain;

    string public baseUri = 'https://example.com/';
    string public baseUriSuffix = '.json';
    bool public baseUriLocked = false;

    mapping(uint256 => Property) public properties;
    mapping(uint256 => bool) public isPropertiesInitialized;
    mapping(uint256 => uint256) public supply;

    event Create(uint256 id);

    modifier exists(uint256 id) {
        require(idCounter > id, 'Bad id');
        _;
    }

    constructor(uint256 nftChain_) ERC1155('') {
        nftChain = nftChain_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Changes base uri for all tokens
    /// @param baseUri_ new base uri
    /// @param baseUriSuffix_ new base uri suffix
    function setBaseUri(string calldata baseUri_, string calldata baseUriSuffix_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!baseUriLocked, 'baseUri is locked');
        baseUri = baseUri_;
        baseUriSuffix = baseUriSuffix_;
    }

    /// @dev Prevents base uri from being changed
    function lockBaseUri() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!baseUriLocked, 'baseUri is locked');
        baseUriLocked = true;
    }

    function uri(uint256 _tokenid) public view override returns (string memory) {
        return
            string(abi.encodePacked(baseUri, Strings.toString(_tokenid), baseUriSuffix));
    }

    /// @dev Sets nft chain, preventing minting NFTs on other chains
    /// @param nftChain_ Chaid ID of the NFT chain
    function setNftChain(uint256 nftChain_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nftChain = nftChain_;
    }

    /// @dev Sets properties for NFTs with IDs `id`
    /// @param id NFT type ID
    /// @param props Properties of the NFT
    function setProperties(uint256 id, Property calldata props)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(idCounter > id, 'Bad id');
        require(
            properties[id].maxAllocationSize == 0 ||
                !props.singleton ||
                properties[id].singleton ||
                !isPropertiesInitialized[id],
            'singleton can only be disabled'
        );
        require(
            !props.transferable ||
                properties[id].transferable ||
                !isPropertiesInitialized[id],
            'transferable can only be disabled'
        );
        require(
            props.maxSupply != 0 && props.maxSupply >= supply[id],
            'max supply too low'
        );

        require(
            props.maxAllocationSize != 0 &&
                props.maxAllocationSize >= props.minAllocationSize,
            'bad allocation size'
        );

        bool buyable = props.price != 0;

        require(
            !props.buybackGarantee || props.singleton,
            'cant buyback not singleton tokn'
        );
        require(
            !props.buybackGarantee || !props.transferable,
            'cant buyback transferable'
        );
        require(buyable || !props.buybackGarantee, 'buyback not buyable');
        require(!buyable || props.token != address(0), 'bad token');
        require(!props.burnOnBuy || buyable, 'cant burn not buyable');

        require(!props.burnOnBuy || !props.buybackGarantee, 'cant burn and buyback');

        properties[id] = props;
        isPropertiesInitialized[id] = true;
    }

    /// @dev Returns NFT properties. Needed because the
    ///   "free" getter from public var returns a tuple.
    /// @param id NFT type ID to return properties of
    function getProperties(uint256 id) external view returns (Property memory) {
        return properties[id];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /// @dev Burns `amount` tokens of ID `id` from address `from`
    /// @param from Address to burn tokens from
    /// @param id ID of token to burn
    /// @param amount Amount of tokens to burn
    function forceBurn(
        address from,
        uint256 id,
        uint256 amount
    ) external onlyRole(BURNER_ROLE) exists(id) {
        _burn(from, id, amount);
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual override {
        // if (hasRole(MINTER_ROLE, operator)) return;
        uint256 length = ids.length;

        for (uint256 i; i < length; ) {
            if (
                to != address(0) &&
                balanceOf(to, ids[i]) != 0 &&
                properties[ids[i]].singleton
            ) revert('excess of singleton amount');
            if (
                from != address(0) && to != address(0) && !properties[ids[i]].transferable
            ) revert('token not transferable');
            if (to == address(0)) supply[ids[i]] -= amounts[i];
            unchecked {
                ++i;
            }
        }
    }

    /// @dev creates new type of nft with such properties
    /// @param property breaf desription of current nft
    function create(Property calldata property) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 id = idCounter;
        idCounter++;
        setProperties(id, property);

        emit Create(id);
    }

    function _mint2(
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        require(properties[id].maxSupply >= supply[id] + amount, 'max supply reached');

        if (properties[id].singleton) {
            require(balanceOf(to, id) + amount <= 1, 'You cant have more than one');
        }

        _mint(to, id, amount, '');
        supply[id] += amount;
    }

    /// @dev Mints tokens for internal usage, ignores mintable prop
    /// @param to token recipient
    /// @param id token ID
    /// @param amount amount of token to mint
    function mintInternal(
        address to,
        uint256 id,
        uint256 amount
    ) external exists(id) onlyRole(INTERNAL_MINTER_ROLE) {
        require(block.chainid == nftChain, 'cant mint nfts on other chains');
        _mint2(to, id, amount);
    }

    /// @dev mints nfts
    /// @param to address of minter
    /// @param id specific nft id
    /// @param amount specific quantity of nft with current id
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) exists(id) {
        require(block.chainid == nftChain, 'cant mint nfts on other chains');
        require(properties[id].mintable, 'not mintable');
        _mint2(to, id, amount);
    }

    struct MintBatch {
        address to;
        uint256[] amounts;
    }

    /// @dev mint batch of nfts
    /// @param batch array of nfts to mint
    function mintBatch(MintBatch[] memory batch) external onlyRole(MINTER_ROLE) {
        require(block.chainid == nftChain, 'cant mint nfts on other chains');

        for (uint256 i; i < batch.length; ) {
            for (uint256 j = 0; j < batch[i].amounts.length; ) {
                require(properties[j].mintable, 'not mintable');

                _mint2(batch[i].to, j, batch[i].amounts[j]);

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Returns balances of all tokens of a user
    /// @param user Address of user to return balances of
    function balanceOfAllBatch(address user) external view returns (uint256[] memory) {
        uint256 idCounter_ = idCounter;
        address[] memory users = new address[](idCounter_);
        uint256[] memory ids = new uint256[](idCounter_);

        for (uint256 i; i < idCounter_; ) {
            users[i] = user;
            ids[i] = i;
            unchecked {
                ++i;
            }
        }

        return balanceOfBatch(users, ids);
    }
}