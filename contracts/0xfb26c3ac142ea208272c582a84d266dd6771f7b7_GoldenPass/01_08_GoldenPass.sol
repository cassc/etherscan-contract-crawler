// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

import {ERC1155} from "@solmate/tokens/ERC1155.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import {IOddworx} from "$/IOddworx.sol";
import {IOddworxStaking} from "$/IOddworxStaking.sol";

interface IGoldenPass {
    function burn(address from, uint256 amount) external;
}

// slither-disable-next-line missing-inheritance
contract GoldenPass is IGoldenPass, ERC1155, Ownable {
    using Strings for uint8;
    using Strings for uint160;

    /// @dev 0x843ce46b
    error InvalidClaimAmount();
    /// @dev 0xb05e92fa
    error InvalidMerkleProof();
    /// @dev 0xb36c1284
    error MaxSupply();
    /// @dev 0x59907813
    error OnlyController();
    /// @dev 0xa6802b50
    error PresaleOff();
    /// @dev 0xf81942c9
    error ReachedMaxPerTx();
    /// @dev 0x3afc8ce9
    error SaleOff();

    // Immutable

    uint256 public constant TOTAL_TOKENS_AVAILABLE = 500;
    uint256 public constant MAX_PER_TX = 1;
    /// @dev price in ODDX
    uint256 public constant UNIT_PRICE = 300 ether;
    IOddworxStaking public immutable oddxStaking;
    bytes32 public immutable merkleRoot;
    address private genzeeAddress;

    // Mutable

    bool public isPresaleActive = false;
    uint256 public totalSupply = 0;
    bool public isSaleActive = false;
    string private _uri;

    /// @dev we know no one is allow-listed to claim more than 255, and we
    ///      found out uint8 was cheaper than other uints by trial
    mapping(address => uint8) public amountClaimedByUser;

    /// @dev addresses authorized to burn tokens
    mapping(address => bool) public isController;

    // Constructor

    constructor(
        IOddworxStaking oddxStaking_,
        address genzeeAddress_,
        string memory uri_,
        bytes32 merkleRoot_
    ) {
        oddxStaking = oddxStaking_;
        genzeeAddress = genzeeAddress_;
        _uri = uri_;
        merkleRoot = merkleRoot_;
    }

    // Modifier

    modifier onlyController() {
        if (!isController[msg.sender]) revert OnlyController();
        _;
    }

    // Owner Only

    function setURI(string calldata newUri) external onlyOwner {
        _uri = newUri;
    }

    function setIsSaleActive(bool newIsSaleActive) external onlyOwner {
        isSaleActive = newIsSaleActive;
    }

    function setIsPresaleActive(bool newIsPresaleActive) external onlyOwner {
        isPresaleActive = newIsPresaleActive;
    }

    function setIsController(address controller, bool newIsController)
        external
        onlyOwner
    {
        isController[controller] = newIsController;
    }

    // Controller Only

    function burn(address from, uint256 amount) external onlyController {
        _burn(from, 1, amount);
        // totalSupply is not decremented because otherwise people will be able
        // to mint after the limit is reached
    }

    // User

    /// @notice Mint function to be used on presale by addresses in the allow-list.
    ///         Caller should have enough ODDX.
    function premint(
        uint8 amount,
        uint8 totalAmount,
        uint256[] calldata nftIds,
        bytes32[] calldata proof
    ) external {
        if (!isPresaleActive) revert PresaleOff();
        unchecked {
            totalSupply += amount;
            if (totalSupply > TOTAL_TOKENS_AVAILABLE) revert MaxSupply();
            if (amountClaimedByUser[msg.sender] + amount > totalAmount)
                revert InvalidClaimAmount();
            // disabling slither reentrancy check cuz we trust ODDX
            // slither-disable-next-line reentrancy-no-eth
            oddxStaking.buyItem(0x0103, amount * UNIT_PRICE, genzeeAddress, nftIds, msg.sender);
        }

        // Check proof
        bytes32 leaf = keccak256(
            abi.encodePacked(
                uint160(msg.sender).toHexString(20),
                ":",
                totalAmount.toString()
            )
        );
        bool isProofValid = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isProofValid) revert InvalidMerkleProof();

        // This is not before the proof check cuz it will add 20k extra gas cost
        // if the user doesn't have the token already
        unchecked {
            amountClaimedByUser[msg.sender] += amount;
        }
        _mint(msg.sender, 1, amount, "");
    }

    /// @notice Mint function to be used on public sale, anyone can call this.
    ///         Caller should have enough ODDX.
    function mint(uint256 amount, uint256[] calldata nftIds) external {
        if (!isSaleActive) revert SaleOff();
        if (amount > MAX_PER_TX) revert ReachedMaxPerTx();
        unchecked {
            if (amount + totalSupply > TOTAL_TOKENS_AVAILABLE)
                revert MaxSupply();
            totalSupply += amount;

            oddxStaking.buyItem(0x0103, amount * UNIT_PRICE, genzeeAddress, nftIds, msg.sender);
        }

        _mint(msg.sender, 1, amount, "");
    }

    // Overrides

    function uri(uint256) public view override returns (string memory) {
        return _uri;
    }
}