// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';
import '../utils/Ownable.sol';
import './OmnuumCAManager.sol';
import './SenderVerifier.sol';

/// @title NftFactory - Factory contract for deploying new NFT PFP projects for creators
/// @author Omnuum Dev Team - <[email protected]>
contract NftFactory is Ownable {
    event NftContractDeployed(address indexed nftContract, address indexed creator, uint256 indexed collectionId);

    address public immutable caManager;
    address public immutable nftContractBeacon;
    address public omnuumSigner;

    /// @notice constructor
    /// @param _caManager CA manager address managed by Omnuum
    /// @param _nftContractBeacon Nft contract beacon address managed by Omnuum
    /// @param _omnuumSigner Address of Omnuum signer for creating and verifying off-chain ECDSA signature
    constructor(
        address _caManager,
        address _nftContractBeacon,
        address _omnuumSigner
    ) Ownable() {
        caManager = _caManager;
        omnuumSigner = _omnuumSigner;
        nftContractBeacon = _nftContractBeacon;
    }

    /// @notice deploy
    /// @param _maxSupply max amount can be minted
    /// @param _coverBaseURI metadata uri for before reveal
    /// @param _collectionId collection id
    /// @param _payload payload for signature to verify collection id
    function deploy(
        uint32 _maxSupply,
        string calldata _coverBaseURI,
        uint256 _collectionId,
        string calldata _name,
        string calldata _symbol,
        SenderVerifier.Payload calldata _payload
    ) external {
        address senderVerifier = OmnuumCAManager(caManager).getContract('VERIFIER');
        SenderVerifier(senderVerifier).verify(omnuumSigner, msg.sender, 'DEPLOY_COL', _collectionId, _payload);

        /// @dev 0x9da8ac6a == keccak256('initialize(address,address,uint32,string,address,string,string)')
        bytes memory data = abi.encodeWithSelector(
            0xc903b7f2,
            caManager,
            omnuumSigner,
            _maxSupply,
            _coverBaseURI,
            msg.sender,
            _name,
            _symbol
        );

        BeaconProxy beacon = new BeaconProxy(nftContractBeacon, data);
        emit NftContractDeployed(address(beacon), msg.sender, _collectionId);
    }

    /// @notice changeOmnuumSigner
    /// @param _newSigner Address of Omnuum signer for replacing previous signer
    function changeOmnuumSigner(address _newSigner) external onlyOwner {
        require(_newSigner != address(0), 'AE1');
        omnuumSigner = _newSigner;
    }
}