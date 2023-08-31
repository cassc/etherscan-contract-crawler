// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Import ECDSA functions from OpenZeppelin library for cryptographic operations.
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// The MFPurrsNamingAgency contract is used to assign names to MFPurrs.
contract MFPurrsNamingAgency {

    // Custom error messages.
    error OnlyController();
    error NameUsed();
    error AlreadyNamed();
    error InvalidOwnershipProof();
    error SignatureExpired();
    error WithdrawlFailed();
    error InvalidFeeProvided();

    uint256 public NAMING_FEE = 0.0015 * 1 ether;

    // A mapping to keep track of all MFPurrs by their tokenId.
    mapping (uint256 => string) names;

    // A mapping to ensure that names are unique.
    mapping (string => uint256) usedNames;

    // The address that has control over the contract.
    address public CONTROLLER;
    address public immutable FEE_WALLET = 0x18E10191877C19990c9ae1e08d7104Cd783F1BdB;

    // Modifier to restrict access to the controller.
    modifier onlyController() {
        if (msg.sender != CONTROLLER) {
            revert OnlyController();
        }
        _;
    }

    // Constructor sets the contract deployer as the controller.
    constructor () {
        CONTROLLER = msg.sender;
    }

    function namePurr(uint256 tokenId, string calldata name, uint256 expiry, bytes calldata signature) external payable {
        if (msg.value != NAMING_FEE) {
            revert InvalidFeeProvided();
        }
        // Ensure the MFPurr hasn't been named already.
        if (bytes(names[tokenId]).length != 0) {
            revert AlreadyNamed();
        }

        // Ensure the name hasn't been used already.
        if (!nameAvailable(name)) {
            revert NameUsed();
        }

        if (block.timestamp >= expiry) {
            revert SignatureExpired();
        }

        // Verify the signature to prove ownership.
        bytes32 message = keccak256(
            abi.encode(msg.sender, uint256(tokenId), name, uint256(expiry))
        );
        if (
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(message),
                signature
            ) != CONTROLLER
        ) {
            revert InvalidOwnershipProof();
        }

        // Name the MFPurr and record its details.
        names[tokenId] = name;
        usedNames[name] = 1;
    }

    // Function to fetch the name of a MFPurr by tokenId.
    function getName(uint256 tokenId) public view returns (string memory) {
        return names[tokenId];
    }

    // Function to check if a name is available.
    function nameAvailable(string calldata name) public view returns (bool) {
        return usedNames[name] == 0;
    }

    function withdraw() external onlyController {
        (bool success,) = address(FEE_WALLET).call{value: address(this).balance}("");
        if (!success) {
            revert WithdrawlFailed();
        }
    }

    function updateFee(uint256 _fee) external onlyController {
        NAMING_FEE = _fee;
    }

    function updateController(address _controller) external onlyController {
        CONTROLLER = _controller;
    }
}