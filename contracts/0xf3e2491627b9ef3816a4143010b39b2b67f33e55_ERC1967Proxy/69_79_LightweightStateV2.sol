// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@rarimo/evm-bridge/bridge/proxy/UUPSSignableUpgradeable.sol";
import "@rarimo/evm-bridge/utils/Signers.sol";

import "./interfaces/ILightweightStateV2.sol";

contract LightweightStateV2 is ILightweightStateV2, UUPSSignableUpgradeable, Signers {
    address public override sourceStateContract;

    uint256 internal _currentGistRoot;

    // gist root => GistRootData
    mapping(uint256 => GistRootData) internal _gistsRootData;

    // identity id => IdentityInfo
    mapping(uint256 => IdentityInfo) internal _identitiesInfo;

    function __LightweightStateV2_init(
        address signer_,
        address sourceStateContract_,
        string calldata chainName_
    ) external initializer {
        __Signers_init(signer_, chainName_);

        sourceStateContract = sourceStateContract_;
    }

    function changeSigner(
        bytes calldata newSignerPubKey_,
        bytes calldata signature_
    ) external override {
        _checkSignature(keccak256(newSignerPubKey_), signature_);

        signer = _convertPubKeyToAddress(newSignerPubKey_);
    }

    function changeSourceStateContract(
        address newSourceStateContract_,
        bytes calldata signature_
    ) external override {
        require(newSourceStateContract_ != address(0), "Bridge: zero address");

        validateChangeAddressSignature(
            uint8(MethodId.ChangeSourceStateContract),
            address(this),
            newSourceStateContract_,
            signature_
        );

        sourceStateContract = newSourceStateContract_;
    }

    function signedTransitState(
        uint256 prevState_,
        uint256 prevGist_,
        StateData calldata stateData_,
        GistRootData calldata gistData_,
        bytes calldata proof_
    ) external override {
        _checkMerkleSignature(_getSignHash(stateData_, gistData_, prevState_, prevGist_), proof_);

        IdentityInfo storage _identityInfo = _identitiesInfo[stateData_.id];

        require(
            _identityInfo.statesData[stateData_.state].createdAtTimestamp == 0,
            "LightweightStateV2: unable to update already stored states"
        );

        if (stateData_.createdAtTimestamp > _getLastStateData(stateData_.id).createdAtTimestamp) {
            _identityInfo.lastState = stateData_.state;
        }

        _identityInfo.statesData[stateData_.state] = stateData_;
        _identityInfo.statesData[prevState_].replacedByState = stateData_.state;

        if (_currentGistRoot != gistData_.root) {
            require(
                _gistsRootData[gistData_.root].createdAtTimestamp == 0,
                "LightweightStateV2: unable to update already stored gist data"
            );

            if (
                gistData_.createdAtTimestamp > _gistsRootData[_currentGistRoot].createdAtTimestamp
            ) {
                _currentGistRoot = gistData_.root;
            }

            _gistsRootData[gistData_.root] = gistData_;
            _gistsRootData[prevGist_].replacedByRoot = gistData_.root;
        }

        emit SignedStateTransited(
            gistData_.root,
            stateData_.id,
            stateData_.state,
            prevState_,
            prevGist_
        );
    }

    function getStateInfoById(
        uint256 identityId_
    ) external view override returns (StateInfo memory) {
        return _getStateInfo(identityId_, getIdentityLastState(identityId_));
    }

    function getStateInfoByIdAndState(
        uint256 identityId_,
        uint256 state_
    ) external view override returns (StateInfo memory) {
        return _getStateInfo(identityId_, state_);
    }

    function getGISTRoot() external view override returns (uint256) {
        return _currentGistRoot;
    }

    function getCurrentGISTRootInfo() external view override returns (GistRootInfo memory) {
        return _getGISTRootInfo(_currentGistRoot);
    }

    function getGISTRootInfo(uint256 root_) external view override returns (GistRootInfo memory) {
        return _getGISTRootInfo(root_);
    }

    function idExists(uint256 identityId_) public view override returns (bool) {
        return _identitiesInfo[identityId_].lastState > 0;
    }

    function stateExists(uint256 identityId_, uint256 state_) public view override returns (bool) {
        return _identitiesInfo[identityId_].statesData[state_].createdAtTimestamp > 0;
    }

    function getIdentityLastState(uint256 identityId_) public view returns (uint256) {
        return _identitiesInfo[identityId_].lastState;
    }

    function _authorizeUpgrade(
        address newImplementation_,
        bytes calldata signature_
    ) internal override {
        require(newImplementation_ != address(0), "LightweightStateV2: zero address");

        validateChangeAddressSignature(
            uint8(MethodId.AuthorizeUpgrade),
            address(this),
            newImplementation_,
            signature_
        );
    }

    function _authorizeUpgrade(address) internal pure override {
        revert("LightweightStateV2: this upgrade method is off");
    }

    function _getLastStateData(uint256 identityId_) internal view returns (StateData storage) {
        return _identitiesInfo[identityId_].statesData[getIdentityLastState(identityId_)];
    }

    function _getStateInfo(
        uint256 identityId_,
        uint256 state_
    ) internal view returns (StateInfo memory) {
        IdentityInfo storage _identityInfo = _identitiesInfo[identityId_];

        bool isLastState_ = _identityInfo.lastState == state_;

        StateData memory stateData_ = _identityInfo.statesData[state_];
        StateData storage _replacedStateData = _identityInfo.statesData[
            stateData_.replacedByState
        ];

        return
            StateInfo({
                id: stateData_.id,
                state: stateData_.state,
                replacedByState: stateData_.replacedByState,
                createdAtTimestamp: stateData_.createdAtTimestamp,
                replacedAtTimestamp: isLastState_ ? 0 : _replacedStateData.createdAtTimestamp,
                createdAtBlock: stateData_.createdAtBlock,
                replacedAtBlock: isLastState_ ? 0 : _replacedStateData.createdAtBlock
            });
    }

    function _getGISTRootInfo(uint256 root_) internal view returns (GistRootInfo memory) {
        bool isCurrentRoot_ = root_ == _currentGistRoot;

        GistRootData memory rootData_ = _gistsRootData[root_];
        GistRootData storage _replacedRootData = _gistsRootData[rootData_.replacedByRoot];

        return
            GistRootInfo({
                root: rootData_.root,
                replacedByRoot: rootData_.replacedByRoot,
                createdAtTimestamp: rootData_.createdAtTimestamp,
                replacedAtTimestamp: isCurrentRoot_ ? 0 : _replacedRootData.createdAtTimestamp,
                createdAtBlock: rootData_.createdAtBlock,
                replacedAtBlock: isCurrentRoot_ ? 0 : _replacedRootData.createdAtBlock
            });
    }

    function _getSignHash(
        StateData calldata stateData_,
        GistRootData calldata gistData_,
        uint256 prevState_,
        uint256 prevGist_
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    sourceStateContract,
                    _encodeStateData(stateData_),
                    _encodeGistData(gistData_),
                    prevState_,
                    prevGist_
                )
            );
    }

    function _encodeStateData(StateData calldata stateData_) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                stateData_.id,
                stateData_.state,
                stateData_.replacedByState,
                stateData_.createdAtTimestamp,
                stateData_.createdAtBlock
            );
    }

    function _encodeGistData(
        GistRootData calldata gistData_
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                gistData_.root,
                gistData_.replacedByRoot,
                gistData_.createdAtTimestamp,
                gistData_.createdAtBlock
            );
    }
}