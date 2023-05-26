// SPDX-License-Identifier: MIT
//                                                ▄▓███▌p
//                                               ║███████H
//    ╓▓████▓▄▄φ,          ,▄▄▓▓██████▓▓▄▄,      ║███████¬
//    █████████████▄▄╓  ╓▓██████████████████▓▄    ╙▀▀█▀▀\`
//    "▀██████▀████████████████████████████████▄
//      └▀█████▓▄⌠╙▀█████████████████████████████▌
//         ▀▀█████▓▓███████████████████████████████
//            ▀▀████████████████████████████████████
//               ║██████████████████████████████████▌
//               ▓███████████████████████████████████
//               ▓███████████████████████████████████
//               ▀███████████████████████████████████p
//                █████████████████████████████████████▌▄
//                ╙████████████████████████████████▀██████▄φ
//                 ╙███████████████████████████████▄▄▐▀██████▄
//                   ▀█████████████████████████████████████████▄
//                     ▀██████████████████████▀  └▀▀▓███████████⌐
//                        ▀▀██████████████▀▀└          └╙▀▀▀█▀▀╙
//                            ▀▀▀▀▀▀▀▀▀▀
//                     
//   
//     ,▄▄▄╓▄████▄▄▄, ╓▄▄▄▄,▄▄▄▄▄▄, ▄▄▄▄,╓▄▄╓ ╓▄▄▄▄▄▄╓ .╓▄▄▄▄▄▄,
//   ,████▀▀████▓████╓████████▓██████████████████▓▓▓▌▀█████▀▀████
//   ║████▄▄████¬████████▀████▄▄▓▓▓████▓ ╙▀▀▀▄▓▓▓▓████████▄╓▄████
//    ╙▀▀▀▀▀▀▀▀▀ "▀▀▀▀▀▀  ╙▀▀▀▓▀▀▀╙╙▀▀▀L     ▀▀▀▓▓▓▀▀╨ ╙▀▀▓▓▀▀▀╙
//
//
//           dverso Droids NFT contract, our avatars!
//                     
//            
//          If you are here to check out what's going on
//             probably you can help us building it.
//                           Join us at
//                      https://dverso.io/
//
//
//

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; //42, meaning of life
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./operatorfilterer/RevokableDefaultOperatorFilterer.sol";
import "fpe-map/contracts/FPEMap.sol";
import "./DroidsAllowance.sol";
import "./DroidsRandomness.sol";
import "./ERC2981.sol";

contract Droids is 
    ERC721A,
    ERC2981ContractWideRoyalties,
    DroidsAllowance,
    DroidsRandomness,
    ReentrancyGuard,
    RevokableDefaultOperatorFilterer {

    using FPEMap for uint256;
    using Strings for uint256;
    /*************************************************************
    *                            Constants
    *************************************************************/

    uint256 public constant _droidsupply = 1111;
    uint256 public constant _pblimit = 10;
    uint256 public constant _wlcost = 0.033 ether;
    uint256 public constant _pbcost = 0.055 ether;

    /*************************************************************
    *                            Storage
    *************************************************************/
    mapping(address => uint256) public _claimed;
    mapping(address => uint256) public _wlminted;
    mapping(address => uint256) public _publicminted;

    string public _unrevealedcid;
    string public _cid;
     /**
     * @dev Phases of the whitelist
     * @dev 0 = Nothing
     * @dev 1 = Wl Sale
     * @dev 2 = Public
     */
    uint256 public _phase = 0;  

    constructor(
        string memory unrevealedcid_,
        string memory cid_,
        address allowanceSigner_,
        address vrfCoordinator_,
        bytes32 vrfKeyHash_,
        uint64 vrtSubscriptionId_
    )

    ERC721A("Droids", "DROIDS")
    DroidsRandomness(vrfCoordinator_,vrfKeyHash_,vrtSubscriptionId_) {
        _unrevealedcid = unrevealedcid_;
        _cid = cid_;
        _setRoyalties(0x7D33c493e2453dF879d8277F2DfAcBa5626fB461 , 750);
        _setAllowancesSigner(allowanceSigner_);
    }

    

    function owner() public view virtual override (Ownable, RevokableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    function setPhase(uint256 phase) external onlyOwner {
        _phase = phase;
    }

    function updateCid(string memory unrevealedcid_, string memory cid_) external onlyOwner {
        _unrevealedcid = unrevealedcid_;
        _cid = cid_;
    }
    
    function mintPublic(uint256 quantity) external payable {
        require(_phase == 2,"NOT_PUBLIC_PHASE");
        require(tx.origin == msg.sender,"NOT_EOA");
        require(quantity > 0,"QUANTITY_ZERO");
        require(_totalMinted() + quantity <= _droidsupply,"MAX_SUPPLY_REACHED");
        require(msg.value >= quantity * _pbcost, "INSUFFICIENT_PAYMENT");
        require(_publicminted[msg.sender] + quantity <= _pblimit,"MAX_PUBLIC_MINT_REACHED");
        
        _publicminted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function mintAllowlist(
        uint256 quantity,
        uint256 limit,
        uint256 isClaim,
        uint256 nonce,
        bytes memory signature
    ) external payable {
        require(tx.origin == msg.sender,"NOT_EOA");
        require(quantity > 0,"QUANTITY_ZERO");
        validateSignature(
            msg.sender,
            limit,
            isClaim,
            nonce,
            signature
        );
        require(_totalMinted() + quantity <= _droidsupply,"MAX_SUPPLY_REACHED");

        if (isClaim == 1) {
            require(_claimed[msg.sender] + quantity <= limit,"MAX_CLAIM_REACHED");
            _claimed[msg.sender] += quantity;
        } else {
            require(_phase == 1,"NOT_WL_PHASE");
            require(msg.value >= quantity * _wlcost, "INSUFFICIENT_PAYMENT");
            require(_wlminted[msg.sender] + quantity <= limit,"MAX_WL_MINT_REACHED");
            _wlminted[msg.sender] += quantity;
        }

        _mint(msg.sender, quantity);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A,ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _unrevealedUri() internal view virtual returns (string memory) {
        return string(abi.encodePacked("ipfs://", _unrevealedcid));
    }
    /**
     * @notice Returns the URI for the token with the given id and fpe mapped with the seed
     */
    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
        if (!_exists(_id)) revert URIQueryForNonexistentToken();
        if (randomnessFulfilled() == false) {
            return _unrevealedUri();
        }
        return string(abi.encodePacked("ipfs://", _cid,"/",_id.fpeMappingFeistelAuto(seed(), _droidsupply).toString(),".json"));
    }

    /**
     * @notice Function to withdraw the funds from the contract
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if(balance > 0){
            Address.sendValue(payable(owner()), balance);
        }
    }
}