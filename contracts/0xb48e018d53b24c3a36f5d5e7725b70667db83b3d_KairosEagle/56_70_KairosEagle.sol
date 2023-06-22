// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

//                            [email protected]@@@@#########@@@@a.
//                        [email protected]@######@@@[email protected]@mm######@@@a.
//                   .a####@@@@@@@@@@@@@@@@@@@[email protected]@##@@v;%%,.
//                .a###[email protected]@@@@@@@[email protected]@@@#@v;%%%vv%%,
//             .a##[email protected]@@@@@@@vv%%%%;S,  .S;%%[email protected]@#v;%%'/%vvvv%;
//           .a##@[email protected]@@@@vv%%vvvvvv%%;SssS;%%[email protected];%%./%vvvvvv%;
//         ,a##[email protected]@@vv%%%@@@@@@@@@@@@mmmmmmmmmvv;%%%%vvvvvvvvv%;
//         .a##@@@@@@@@@@@@@@@@@@@@@@@mmmmmvv;%%%%%vvvvvvvvvvv%;
//        ###[email protected]@@v##@[email protected]@@@@@@@@@mmv;%;%;%;%;%;%;%;%;%;%;%,%vv%'
//       a#[email protected]@@@v##[email protected]@@@@@@@###@@@@@%v%v%v%v%v%v%v%      ;%%;'
//      ',[email protected]@@@@@@[email protected]@@@@@@@v###[email protected]@@nvnvnvnvnvnvnvnv'     .%;'
//      a###@@@@@@@###[email protected]@@v##[email protected]@@mnmnmnmnmnmnmnmnmn.     ;'
//     ,###[email protected]@@@v##[email protected]@@@@@[email protected]@@@v##[email protected]@@@@v###[email protected]@@##@.
//     ###[email protected]@@@@@[email protected]@###[email protected]@@@@@@@[email protected]@@@@@v##[email protected]@@v###[email protected]@.
//    [email protected]@@@@@@@@@v##[email protected]@@@@@@@@@@@@@;@@@[email protected]@@@v##[email protected]@@@@@a
//   ',@@@@@@;@@@@@@[email protected]@@@@@@@@@@@@@@;%@@@@@@@@@[email protected]@@@;@@@@@a
//  [email protected]@@@@@;%@@;@@@@@@@;;@@@@@;@@@@;%%;@@@@@;@@@@;@@@;@@@@@@.
// ,[email protected]@@;vv;@%;@@@@@;%%v%;@@@;@@@;%vv%%;@@@;%;@@;%@@@;%;@@;%@@a
//   [email protected]@@@@@;%@@;@@@@@@@;;@@@@@;@@@@;%%;@@@@@;@@@@;@@@;@@@@@@.
// ,[email protected]@@;vv;@%;@@@@@;%%v%;@@@;@@@;%vv%%;@@@;%;@@;%@@@;%;@@;%@@a
//  [email protected];vv;%%%;@@;%%;vvv;%%@@;%;@;%vvv;%;@@;%%%;@;%;@;%%%@@;%%;.`
// ;@;%;vvv;%;@;%%;vv;%%%%v;%%%;%vv;%%v;@@;%vvv;%;%;%;%%%;%%%%;.%,
// %%%;vv;%;vv;%%%v;%%%%;vvv;%%%v;%%%;vvv;%;vv;%%%%%;vv;%%%;vvv;.%%%,
// ;vvv;%%;vv;%%;vv;%%%;vv;%%%;vvv;%;vv;%;vv;%;%%%;vv;%%%%;vv;%%.%v;v%
// vv;%;vvv;%;vv;;%%%%%%;%%%%;vv;%%%%;%%%%;%%;%%;%%;vv;%%%%;%%%;v.%vv;
// ;%%%%;%%%%%;%%%%%;%%%%;%%%%;%%%;%%%;%%%%%%%;%%%%%;%%%;%%%%;%%;.%%;%

// &&&&@7   :[email protected]@@@P.     [email protected]@@@@@B       [email protected]&&@G  ?B&@@@@@@@@@@&#Y.       :!YGB#BG5?~       ^5#&@@@@@@@&7
// @@@@@7  ^#@@@@5.     [email protected]@@@@@@@?      [email protected]@@@B  ^^#@@@@@##&@@@@@P     :Y&@@@@@@@@@@BJ.   ^&@@@@@####B!
// @@@@@7 ~&@@@@?      .#@@@&&@@@&:     [email protected]@@@B    #@@@@5 [email protected]@@@#     [email protected]@@@@@@@@@#~  [email protected]@@@@J.
// @@@@@7~&@@@&~       [email protected]@@@[email protected]@@@5     [email protected]@@@B   .#@@@@5   [email protected]@@@#     .!^[email protected]@@@@@@@@@#: :[email protected]@@@&BY!:
// @@@@@[email protected]@@@#:      [email protected]@@@#. #@@@@~    [email protected]@@@B   .#@@@@5~YP&@@@#7  :[email protected]@@@@@@@@@@@@@@~  .?G&@@@@@&BJ:
// @@@@@7 [email protected]@@@#^     [email protected]@@@[email protected]@@@#7!. [email protected]@@@B   .#@@@@[email protected]@@@G.  !&@@@@@@@@@@@@@@@@@@#:     [email protected]@@@@B
// @@@@@7  [email protected]@@@&~   [email protected]@@@@@@@@@@@@@@?  [email protected]@@@B   .#@@@@5 [email protected]@@@Y   ^Y#@@@@@@@@@@@@@@@#~   .:....:[email protected]@@@&
// @@@@@7   [email protected]@@@&! :&@@@@[email protected]@@@&:  [email protected]@@@B   .#@@@@5  :[email protected]@@@Y    ~#@@@@@@@@@@@@BJ.   .#&&&&&&@@@@@5
// ####&7    J&&&&#^Y&&&&B.     G&##&J  J&##&G   .G###&Y   ^B&&&&?    .~7JJYJPBG5?~      .B&&&&&&&#BP!

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IOwnershipFacet} from "../interface/IOwnershipFacet.sol";

import {DiamondERC721} from "../SupplyPositionLogic/DiamondERC721.sol";
import {SupplyPosition} from "../DataStructure/Storage.sol";
import {supplyPositionStorage} from "../DataStructure/Global.sol";
import {CallerIsNotOwner} from "../DataStructure/Errors.sol";

struct Raffle {
    bytes32 whitelistMerkleRoot;
    uint256 mintCap;
    uint256 mintCapPerAddress;
    uint256 wethUnitPrice;
    uint256 amountMinted;
    mapping(address => uint256) amountMintedBy;
}

struct EagleStorage {
    string baseMetadataUri;
    mapping(uint256 => Raffle) raffle;
}

bytes32 constant EAGLE_STORAGE_POSITION = keccak256("eth.kairosloan.eagle.v1.0");

/**
 * @notice eagleStorage
 */
function eagleStorage() pure returns (EagleStorage storage eagle) {
    bytes32 position = EAGLE_STORAGE_POSITION;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
        eagle.slot := position
    }
}

error InvalidMerkleProof();
error HardCapExceeded();
error RaffleMintCapExceeded();
error AccountMintCapExceeded();

contract KairosEagleFacet is DiamondERC721 {
    using MerkleProof for bytes32[];
    using Strings for uint256;

    IERC20 internal immutable wEth;
    uint256 internal constant HARD_CAP = 555;

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    modifier onlyOwner() {
        // the admin/owner is the same account that can upgrade the protocol.
        address admin = IOwnershipFacet(address(this)).owner();
        if (msg.sender != admin) {
            revert CallerIsNotOwner(admin);
        }
        _;
    }

    constructor(IERC20 _weth) {
        wEth = _weth;
    }

    /**
     * @notice buy
     */
    function buy(bytes32[] calldata merkleProof, uint256 raffleId) external returns (uint256) {
        Raffle storage raffle = eagleStorage().raffle[raffleId];
        bytes32 merkleRoot = raffle.whitelistMerkleRoot;
        uint256 amountMintedByCaller = ++raffle.amountMintedBy[msg.sender];
        uint256 amountMintedInRaffle = ++raffle.amountMinted;

        if (amountMintedByCaller > raffle.mintCapPerAddress) {
            revert AccountMintCapExceeded();
        }
        if (amountMintedInRaffle > raffle.mintCap) {
            revert RaffleMintCapExceeded();
        }
        if (!merkleProof.verifyCalldata(merkleRoot, keccak256(abi.encode(msg.sender)))) {
            revert InvalidMerkleProof();
        }

        wEth.transferFrom(msg.sender, address(this), raffle.wethUnitPrice);

        return mint();
    }

    /**
     * @notice setRaffle
     */
    function setRaffle(
        uint256 raffleId,
        bytes32 whitelistMerkleRoot,
        uint256 mintCapPerAddress,
        uint256 mintCap,
        uint256 wethUnitPrice
    ) external onlyOwner {
        Raffle storage raffle = eagleStorage().raffle[raffleId];
        raffle.whitelistMerkleRoot = whitelistMerkleRoot;
        raffle.mintCapPerAddress = mintCapPerAddress;
        raffle.mintCap = mintCap;
        raffle.wethUnitPrice = wethUnitPrice;
    }

    /**
     * @notice withdrawFunds
     */
    function withdrawFunds() external onlyOwner {
        wEth.transfer(msg.sender, wEth.balanceOf(address(this)));
    }

    /**
     * @notice setBaseMetadataUri
     */
    function setBaseMetadataUri(string calldata baseMetadataUri) external onlyOwner {
        eagleStorage().baseMetadataUri = baseMetadataUri;
        emit BatchMetadataUpdate(1, type(uint256).max); // the max uint signals refresh of the whole collection
    }

    /**
     * @notice tokenURI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked(eagleStorage().baseMetadataUri, tokenId.toString()));
    }

    /**
     * @notice totalSupply
     */
    function totalSupply() external view returns (uint256) {
        return supplyPositionStorage().totalSupply;
    }

    /**
     * @notice getHardCap
     */
    function getHardCap() external pure returns (uint256) {
        return HARD_CAP;
    }

    /**
     * @notice mint
     */
    function mint() internal returns (uint256 tokenId) {
        tokenId = ++supplyPositionStorage().totalSupply;
        if (tokenId >= HARD_CAP) {
            revert HardCapExceeded();
        }
        _safeMint(msg.sender, tokenId);
    }
}