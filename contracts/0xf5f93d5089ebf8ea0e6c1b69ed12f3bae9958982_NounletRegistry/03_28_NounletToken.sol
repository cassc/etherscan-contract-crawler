// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Clone} from "clones-with-immutable-args/src/Clone.sol";
import {ERC1155B, ERC1155BCheckpointable} from "./utils/ERC1155BCheckpointable.sol";
import {PermitBase} from "./utils/PermitBase.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {INounletToken as INounlet} from "./interfaces/INounletToken.sol";
import {INounsDescriptor as IDescriptor} from "./interfaces/INounsDescriptor.sol";
import {INounsSeeder} from "./interfaces/INounsSeeder.sol";
import {INounsToken as INouns} from "./interfaces/INounsToken.sol";

/// @title NounletToken
/// @author Tessera
/// @notice An ERC-1155B implementation for Fractional Nouns
contract NounletToken is Clone, ERC1155BCheckpointable, INounlet, PermitBase {
    /// @dev Using strings library with uint256 types
    using Strings for uint256;
    /// @notice Percentage amount for royalties
    uint96 public constant ROYALTY_PERCENT = 200;
    /// @notice Mapping of token ID to Nounlet seed
    mapping(uint256 => INounsSeeder.Seed) public seeds;
    /// @notice Mapping of token type approvals owner => operator => tokenId => approval status
    mapping(address => mapping(address => mapping(uint256 => bool))) public isApproved;

    /// @dev Modifier for restricting function calls
    modifier onlyAuthorized(address _sender) {
        if (msg.sender != _sender) revert InvalidSender(_sender, msg.sender);
        _;
    }

    /// @notice Mints new fractions for an ID
    /// @param _to Address to mint fraction tokens to
    /// @param _id Token ID to mint
    /// @param _data Extra calldata to include in the mint
    function mint(
        address _to,
        uint256 _id,
        bytes calldata _data
    ) external onlyAuthorized(NOUNLET_REGISTRY()) {
        seeds[_id] = generateSeed(_id);
        _mint(_to, _id, _data);
    }

    /// @notice Burns fractions for multiple IDs
    /// @param _from Address to burn fraction tokens from
    /// @param _ids Token IDs to burn
    function batchBurn(address _from, uint256[] calldata _ids)
        external
        onlyAuthorized(NOUNLET_REGISTRY())
    {
        _batchBurn(_from, _ids);
    }

    /// @notice Permit function that approves an operator for token type with a valid signature
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _id ID of the token type
    /// @param _approved Approval status for the token type
    /// @param _deadline Expiration of the signature
    /// @param _v The recovery ID (129th byte and chain ID) of the signature used to recover the signer
    /// @param _r The first 64 bytes of the signature
    /// @param _s Bytes 64-128 of the signature
    function permit(
        address _owner,
        address _operator,
        uint256 _id,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (block.timestamp > _deadline) revert SignatureExpired(block.timestamp, _deadline);

        // cannot realistically overflow on human timescales
        unchecked {
            bytes32 structHash = _computePermitStructHash(
                _owner,
                _operator,
                _id,
                _approved,
                _deadline
            );

            bytes32 digest = _computeDigest(_computeDomainSeparator(), structHash);

            address signer = ecrecover(digest, _v, _r, _s);

            if (signer == address(0) || signer != _owner) revert InvalidSignature(signer, _owner);
        }

        isApproved[_owner][_operator][_id] = _approved;

        emit SingleApproval(_owner, _operator, _id, _approved);
    }

    /// @notice Permit function that approves an operator for all token types with a valid signature
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _approved Approval status for the token type
    /// @param _deadline Expiration of the signature
    /// @param _v The recovery ID (129th byte and chain ID) of the signature used to recover the signer
    /// @param _r The first 64 bytes of the signature
    /// @param _s Bytes 64-128 of the signature
    function permitAll(
        address _owner,
        address _operator,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (block.timestamp > _deadline) revert SignatureExpired(block.timestamp, _deadline);

        // cannot realistically overflow on human timescales
        unchecked {
            bytes32 structHash = _computePermitAllStructHash(
                _owner,
                _operator,
                _approved,
                _deadline
            );

            bytes32 digest = _computeDigest(_computeDomainSeparator(), structHash);

            address signer = ecrecover(digest, _v, _r, _s);

            if (signer == address(0) || signer != _owner) revert InvalidSignature(signer, _owner);
        }

        isApprovedForAll[_owner][_operator] = _approved;

        emit ApprovalForAll(_owner, _operator, _approved);
    }

    /// @notice Scoped approvals allow us to eliminate some of the risks associated with setting the approval for an entire collection
    /// @param _operator Address of spender account
    /// @param _id ID of the token type
    /// @param _approved Approval status for operator(spender) account
    function setApprovalFor(
        address _operator,
        uint256 _id,
        bool _approved
    ) external {
        isApproved[msg.sender][_operator][_id] = _approved;

        emit SingleApproval(msg.sender, _operator, _id, _approved);
    }

    /// @notice Returns the royalty amount for a given token
    /// @param _salePrice Price of token sold on secondary market
    function royaltyInfo(
        uint256, /* _id */
        uint256 _salePrice
    ) external pure returns (address beneficiary, uint256 royaltyAmount) {
        beneficiary = ROYALTY_BENEFICIARY();
        royaltyAmount = (_salePrice * uint256(ROYALTY_PERCENT)) / 10000;
    }

    /// @notice Transfers multiple token types
    /// @param _from Source address
    /// @param _to Destination address
    /// @param _ids IDs of each token type
    /// @param _amounts Transfer amounts per token type
    /// @param _data Additional calldata
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) public override(ERC1155BCheckpointable, INounlet) {
        super.safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    /// @notice Transfers a single token type
    /// @param _from Source address
    /// @param _to Destination address
    /// @param _id ID of the token type
    /// @param _amount Transfer amount
    /// @param _data Additional calldata
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) public override(ERC1155BCheckpointable, INounlet) {
        require(
            msg.sender == _from ||
                isApprovedForAll[_from][msg.sender] ||
                isApproved[_from][msg.sender][_id],
            "NOT_AUTHORIZED"
        );

        super.safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) public override(ERC1155BCheckpointable, INounlet) {
        super.batchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    /// @notice Transfers a single token type
    /// @param _from Source address
    /// @param _to Destination address
    /// @param _id ID of the token type
    /// @param _amount Transfer amount
    /// @param _data Additional calldata
    function transferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) public override(ERC1155BCheckpointable, INounlet) {
        require(
            msg.sender == _from ||
                isApprovedForAll[_from][msg.sender] ||
                isApproved[_from][msg.sender][_id],
            "NOT_AUTHORIZED"
        );

        super.transferFrom(_from, _to, _id, _amount, _data);
    }

    /// @notice Returns the URI of a token type
    /// @param _id ID of the token type
    function uri(uint256 _id) public view override(ERC1155B, INounlet) returns (string memory) {
        string memory nounId = NOUNS_TOKEN_ID().toString();
        string memory name = string(abi.encodePacked("Nounlet #", _id.toString()));
        string memory description = string(
            abi.encodePacked("Noun ", nounId, " is collectively owned by a 100 member DAO")
        );

        return IDescriptor(NOUNS_DESCRIPTOR()).genericDataURI(name, description, seeds[_id]);
    }

    function contractURI() public view returns (string memory) {
        return
            string(abi.encodePacked("https://nounlets.wtf/api/noun/", NOUNS_TOKEN_ID().toString()));
    }

    function owner() public view returns (address) {
        return ROYALTY_BENEFICIARY();
    }

    /// @notice Generates a random seed for a given token
    /// @param _id ID of the token type
    function generateSeed(uint256 _id) public view returns (INounsSeeder.Seed memory) {
        address descriptor = NOUNS_DESCRIPTOR();
        INounsSeeder.Seed memory noun = INouns(NOUNS_TOKEN()).seeds(NOUNS_TOKEN_ID());
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), _id))
        );

        uint256 backgroundCount = IDescriptor(descriptor).backgroundCount();
        uint256 bodyCount = IDescriptor(descriptor).bodyCount();
        uint256 accessoryCount = IDescriptor(descriptor).accessoryCount();
        uint256 glassesCount = IDescriptor(descriptor).glassesCount();

        return
            INounsSeeder.Seed({
                background: uint48((pseudorandomness) % backgroundCount),
                body: uint48((pseudorandomness >> 48) % bodyCount),
                accessory: uint48((pseudorandomness >> 96) % accessoryCount),
                head: uint48(noun.head),
                glasses: uint48((pseudorandomness >> 192) % glassesCount)
            });
    }

    /// @dev Returns true if this contract implements the interface defined by the given identifier
    function supportsInterface(bytes4 _interfaceId) public view virtual returns (bool) {
        return (_interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            _interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            _interfaceId == 0x2a55205a); // ERC165 Interface ID for ERC2981
    }

    /// @notice Address of NounletRegistry contract
    /// @dev ClonesWithImmutableArgs appends this value to the end of the initial bytecode at index 0
    function NOUNLET_REGISTRY() public pure returns (address) {
        return _getArgAddress(0);
    }

    /// @notice Address of NounsDescriptor contract
    /// @dev ClonesWithImmutableArgs appends this value to the end of the initial bytecode at index 20
    function NOUNS_DESCRIPTOR() public pure returns (address) {
        return _getArgAddress(20);
    }

    /// @notice ID of the NounsToken
    /// @dev ClonesWithImmutableArgs appends this value to the end of the initial bytecode at index 40
    function NOUNS_TOKEN_ID() public pure returns (uint256) {
        return _getArgUint256(40);
    }

    /// @notice Address of the royalty beneficiary
    /// @dev ClonesWithImmutableArgs appends this value to the end of the initial bytecode at index 72
    function ROYALTY_BENEFICIARY() public pure returns (address) {
        return _getArgAddress(72);
    }

    function NOUNS_TOKEN() public pure returns (address) {
        return _getArgAddress(92);
    }
}