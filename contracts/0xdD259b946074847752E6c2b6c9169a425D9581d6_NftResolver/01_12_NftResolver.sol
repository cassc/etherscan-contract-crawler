// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../interface/INftProfile.sol";
import "../interface/INftResolver.sol";
import "./library/Resolver.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NftResolver is Initializable, ReentrancyGuardUpgradeable, UUPSUpgradeable, INftResolver {
    using SafeMathUpgradeable for uint256;

    INftProfile public nftProfile;
    address public owner;

    // ===================================================================================================
    mapping(string => uint256) internal _nonce; // profile nonce for easy clearing of maps
    mapping(Blockchain => IRegex) internal _regexMap; // mapping of chain -> regex contract
    // Storage for owner of profile ======================================================================
    mapping(address => mapping(uint256 => AddressTuple[])) internal _ownerAddrList;
    mapping(address => mapping(uint256 => AddressTuple)) internal _ownerCtx;
    mapping(uint256 => mapping(bytes => bool)) internal _ownerNonEvmMap; // O(1) lookup non-evm
    mapping(uint256 => mapping(address => mapping(bytes => bool))) internal _ownerEvmMap; // O(1) lookup evm
    // ===================================================================================================
    mapping(address => RelatedProfiles[]) internal _approvedEvmList;
    mapping(bytes => bool) internal _approvedMap;
    // ===================================================================================================

    event UpdatedRegex(Blockchain _cid, IRegex _regexAddress);
    event AssociateEvmUser(address indexed owner, string profileUrl, address indexed associatedAddress);
    event CancelledEvmAssociation(address indexed owner, string profileUrl, address indexed associatedAddresses);
    event ClearAllAssociatedAddresses(address indexed owner, string profileUrl);
    event SetAssociatedContract(address indexed owner, string profileUrl, string associatedContract);
    event ClearAssociatedContract(address indexed owner, string profileUrl);
    event AssociateSelfWithUser(address indexed receiver, string profileUrl, address indexed profileOwner);
    event RemovedAssociateProfile(address indexed receiver, string profileUrl, address indexed profileOwner);

    function _onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }

    function _onlyProfileOwner(string memory profileUrl) private view {
        if (nftProfile.profileOwner(profileUrl) != msg.sender) revert NotOwner();
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function initialize(INftProfile _nftProfile) public initializer {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        owner = msg.sender;
        nftProfile = _nftProfile;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // validation helper function for different chains
    function validateAddress(Blockchain cid, string memory chainAddr) private view {
        if (address(_regexMap[cid]) == 0x0000000000000000000000000000000000000000) revert InvalidRegex();
        if (!_regexMap[cid].matches(chainAddr)) revert InvalidAddress();
    }

    function setAssociatedContract(AddressTuple memory inputTuple, string calldata profileUrl) external {
        _onlyProfileOwner(profileUrl);
        uint256 tokenId = nftProfile.getTokenId(profileUrl);

        validateAddress(inputTuple.cid, inputTuple.chainAddr);

        _ownerCtx[msg.sender][tokenId] = inputTuple;

        emit SetAssociatedContract(msg.sender, profileUrl, inputTuple.chainAddr);
    }

    function getApprovedEvm(address _user) external view returns (RelatedProfiles[] memory) {
        return _approvedEvmList[_user];
    }

    function getAllAssociatedAddr(address _user, string calldata profileUrl)
        external
        view
        returns (AddressTuple[] memory)
    {
        uint256 tokenId = nftProfile.getTokenId(profileUrl);
        return _ownerAddrList[_user][tokenId];
    }

    function clearAssociatedContract(string calldata profileUrl) external {
        _onlyProfileOwner(profileUrl);
        uint256 tokenId = nftProfile.getTokenId(profileUrl);

        AddressTuple memory addressTuple;
        _ownerCtx[msg.sender][tokenId] = addressTuple;

        emit ClearAssociatedContract(msg.sender, profileUrl);
    }

    function _sameHash(AddressTuple memory _t1, AddressTuple memory _t2) private pure returns (bool) {
        return
            keccak256(abi.encodePacked(_t1.cid, _t1.chainAddr)) == keccak256(abi.encodePacked(_t2.cid, _t2.chainAddr));
    }

    function _sameStr(string memory _t1, string memory _t2) private pure returns (bool) {
        return keccak256(abi.encodePacked(_t1)) == keccak256(abi.encodePacked(_t2));
    }

    function _evmBased(Blockchain cid) private pure returns (bool) {
        if (cid == Blockchain.ETHEREUM || cid == Blockchain.POLYGON) return true;
        return false;
    }

    // adds multiple addresses at a time while checking for duplicates
    function addAssociatedAddresses(AddressTuple[] calldata inputTuples, string calldata profileUrl) external {
        _onlyProfileOwner(profileUrl);
        uint256 tokenId = nftProfile.getTokenId(profileUrl);
        uint256 l1 = inputTuples.length;
        uint256 nonce = _nonce[profileUrl];

        for (uint256 i = 0; i < l1; ) {
            validateAddress(inputTuples[i].cid, inputTuples[i].chainAddr);

            if (_ownerNonEvmMap[nonce][abi.encode(msg.sender, tokenId, inputTuples[i].cid, inputTuples[i].chainAddr)])
                revert DuplicateAddress();

            if (_evmBased(inputTuples[i].cid)) {
                address dest = Resolver._parseAddr(inputTuples[i].chainAddr);
                if (_ownerEvmMap[nonce][dest][abi.encode(msg.sender, tokenId, inputTuples[i].cid)]) {
                    revert DuplicateAddress();
                }
                _ownerEvmMap[nonce][dest][abi.encode(msg.sender, tokenId, inputTuples[i].cid)] = true;

                emit AssociateEvmUser(msg.sender, profileUrl, dest);
            } else {
                _ownerNonEvmMap[nonce][
                    abi.encode(msg.sender, tokenId, inputTuples[i].cid, inputTuples[i].chainAddr)
                ] = true;
            }

            _ownerAddrList[msg.sender][tokenId].push(inputTuples[i]);

            unchecked {
                ++i;
            }
        }
    }

    // allows for bidirectional association
    function associateSelfWithUsers(string[] calldata urls) external {
        uint256 l1 = urls.length;

        for (uint256 i = 0; i < l1; ) {
            string memory url = urls[i];
            address pOwner = nftProfile.profileOwner(url);
            uint256 tokenId = nftProfile.getTokenId(url);

            // CHECKS
            if (pOwner == msg.sender) revert InvalidSelf();
            if (_approvedMap[abi.encode(pOwner, tokenId, msg.sender)] == true) {
                revert DuplicateAddress();
            }

            // EFFECTS
            // easy access for associator to see their profiles
            _approvedEvmList[msg.sender].push(RelatedProfiles({ addr: pOwner, profileUrl: url }));
            // mapping for O(1) lookup
            _approvedMap[abi.encode(pOwner, tokenId, msg.sender)] = true;

            emit AssociateSelfWithUser(msg.sender, url, pOwner);

            // INTERACTIONS

            unchecked {
                ++i;
            }
        }
    }

    function removeAssociatedProfile(string memory url) external returns (bool) {
        uint256 tokenId = nftProfile.getTokenId(url);
        address pOwner = nftProfile.profileOwner(url);
        uint256 l1 = _approvedEvmList[msg.sender].length;

        if (_approvedMap[abi.encode(pOwner, tokenId, msg.sender)]) {
            for (uint256 i = 0; i < l1; ) {
                if (_sameStr(_approvedEvmList[msg.sender][i].profileUrl, url)) {
                    _approvedEvmList[msg.sender][i] = _approvedEvmList[msg.sender][l1 - 1];
                    _approvedEvmList[msg.sender].pop();
                    _approvedMap[abi.encode(pOwner, tokenId, msg.sender)] = false;

                    emit RemovedAssociateProfile(msg.sender, url, pOwner);

                    return true;
                }

                unchecked {
                    ++i;
                }
            }
        }

        revert ProfileNotFound();
    }

    // removes 1 address at a time
    function removeAssociatedAddress(AddressTuple calldata inputTuple, string calldata profileUrl)
        external
        returns (bool)
    {
        _onlyProfileOwner(profileUrl);
        uint256 tokenId = nftProfile.getTokenId(profileUrl);
        uint256 l1 = _ownerAddrList[msg.sender][tokenId].length;
        uint256 nonce = _nonce[profileUrl];

        for (uint256 i = 0; i < l1; ) {
            validateAddress(inputTuple.cid, inputTuple.chainAddr);

            // EVM based - checksum
            if (_evmBased(inputTuple.cid) && _evmBased(_ownerAddrList[msg.sender][tokenId][i].cid)) {
                address parsed = Resolver._parseAddr(inputTuple.chainAddr);
                address parsedCmp = Resolver._parseAddr(_ownerAddrList[msg.sender][tokenId][i].chainAddr);
                if (
                    parsed == parsedCmp && _ownerEvmMap[nonce][parsed][abi.encode(msg.sender, tokenId, inputTuple.cid)]
                ) {
                    _ownerAddrList[msg.sender][tokenId][i] = _ownerAddrList[msg.sender][tokenId][l1 - 1];
                    _ownerAddrList[msg.sender][tokenId].pop();
                    _ownerEvmMap[nonce][parsed][abi.encode(msg.sender, tokenId, inputTuple.cid)] = false;

                    emit CancelledEvmAssociation(msg.sender, profileUrl, parsed);

                    return true;
                }
            } else if (
                // non-evm
                _sameHash(inputTuple, _ownerAddrList[msg.sender][tokenId][i])
            ) {
                _ownerAddrList[msg.sender][tokenId][i] = _ownerAddrList[msg.sender][tokenId][l1 - 1];
                _ownerAddrList[msg.sender][tokenId].pop();

                _ownerNonEvmMap[nonce][abi.encode(msg.sender, tokenId, inputTuple.cid, inputTuple.chainAddr)] = false;

                return true;
            }

            unchecked {
                ++i;
            }
        }

        revert AddressNotFound();
    }

    // can be used to clear mapping OR more gas efficient to remove multiple addresses
    // nonce increment clears the mapping without having to manually reset state
    function clearAssociatedAddresses(string calldata profileUrl) external {
        _onlyProfileOwner(profileUrl);
        uint256 tokenId = nftProfile.getTokenId(profileUrl);
        delete _ownerAddrList[msg.sender][tokenId];

        unchecked {
            ++_nonce[profileUrl];
        }

        emit ClearAllAssociatedAddresses(msg.sender, profileUrl);
    }

    function evmBased(Blockchain cid) external pure returns (bool) {
        return _evmBased(cid);
    }

    function parseAddr(string memory _a) external pure returns (address) {
        return Resolver._parseAddr(_a);
    }

    function validAddressSize(
        uint256 tokenId,
        address pOwner,
        AddressTuple[] memory rawAssc
    ) private view returns (uint256) {
        uint256 size = 0;

        for (uint256 i = 0; i < rawAssc.length; ) {
            if (_evmBased(rawAssc[i].cid)) {
                // if approved
                if (_approvedMap[abi.encode(pOwner, tokenId, Resolver._parseAddr(rawAssc[i].chainAddr))]) {
                    unchecked {
                        ++size;
                    }
                }
            } else {
                unchecked {
                    ++size;
                }
            }

            unchecked {
                ++i;
            }
        }

        return size;
    }

    // makes sure ownerAddr + profileUrl + associated address is in mapping to allow association
    function associatedAddresses(string calldata profileUrl) external view returns (AddressTuple[] memory) {
        uint256 tokenId = nftProfile.getTokenId(profileUrl);
        address pOwner = nftProfile.profileOwner(profileUrl);
        AddressTuple[] memory rawAssc = _ownerAddrList[pOwner][tokenId];
        AddressTuple[] memory updatedAssc = new AddressTuple[](validAddressSize(tokenId, pOwner, rawAssc));

        uint256 j = 0;
        for (uint256 i = 0; i < rawAssc.length; ) {
            if (_evmBased(rawAssc[i].cid)) {
                // if approved
                if (_approvedMap[abi.encode(pOwner, tokenId, Resolver._parseAddr(rawAssc[i].chainAddr))]) {
                    updatedAssc[j] = rawAssc[i];

                    unchecked {
                        ++j;
                    }
                }
            } else {
                updatedAssc[j] = rawAssc[i];
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        return updatedAssc;
    }

    function associatedContract(string calldata profileUrl) external view returns (AddressTuple memory) {
        uint256 tokenId = nftProfile.getTokenId(profileUrl);
        address pOwner = nftProfile.profileOwner(profileUrl);
        return _ownerCtx[pOwner][tokenId];
    }

    function setRegex(Blockchain _cid, IRegex _regexContract) external onlyOwner {
        _regexMap[_cid] = _regexContract;
        emit UpdatedRegex(_cid, _regexContract);
    }

    function setNftProfile(address profileContract) external onlyOwner {
        nftProfile = INftProfile(profileContract);
    }

    function setOwner(address _new) external onlyOwner {
        owner = _new;
    }
}