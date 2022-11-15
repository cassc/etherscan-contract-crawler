// SPDX-License-Identifier: UNLICENSED
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tokens/ERC1155Guardable.sol";

pragma solidity ^0.8.17;

error WrongValueSent();
error ExceedMaxPerWallet();
error PublicSaleNotStarted();
error AllowlistSaleNotActive();
error AlreadyMinted();
error InvalidProof();
error ExceedMaxSupply();
error NotEnoughStaked();
error MinimumNotHit();

struct StakeDetails {
    uint16 numStaked;
    uint64 stakingStart; 
}

struct PhaseDetails {
    bytes32 root;
    uint64 startTime;
    uint64 endTime;
}

struct NumberMintedPerPhase {
    uint8 phaseOne;
    uint8 phaseTwo;
    uint8 phaseThree;
}

contract LordsAlpha is ERC1155Guardable, Ownable {
    /** @notice MAX_SUPPLY refers to the max supply that is available for the initial mint. The team
      * also has an airdroppable supply of 55 tokens. The final max supply will be 777, and will be set
      * at a later date. This transition from 500 to 777 can happen only once, and the max supply can
      * never exceed 777.
    **/
    uint256 public MAX_SUPPLY = 555;
    uint256 private constant FINAL_MAX_SUPPLY = 777;
    uint256 public constant MINT_PRICE = 0.18 ether;
    uint256 public constant MAX_PER_WALLET_PER_PHASE = 2;
    uint64 public constant MINIMUM_TIME_STAKED_FOR_PREMIUM_REDEMPTION = 90 days;

    uint256 private constant ALPHA_PASS = 1;
    uint256 private constant PREMIUM_PASS = 2;

    mapping(uint256 => uint256) public totalSupply;
    mapping(address => NumberMintedPerPhase) numberMinted;

    mapping(address => StakeDetails) public stakeDetailsFor;

    PhaseDetails public phaseOneDetails;
    PhaseDetails public phaseTwoDetails;

    constructor(bytes32 _phaseOneWhitelistRoot, bytes32 _phaseTwoWhitelistRoot, uint64 startTime) ERC1155Guardable("ipfs://QmQknSe1awZqKUJfTfHo2awHo9UFXkumC4egHRbjt76tKf/") {
        phaseOneDetails = PhaseDetails(_phaseOneWhitelistRoot, startTime, startTime + 2 hours);
        phaseTwoDetails = PhaseDetails(_phaseTwoWhitelistRoot, phaseOneDetails.endTime, phaseOneDetails.endTime + 22 hours);
    }

    function mintAllowlist(bytes32[] calldata proof, uint256 amount) external payable {
        if (block.timestamp < phaseOneDetails.startTime || block.timestamp >= phaseTwoDetails.endTime) revert AllowlistSaleNotActive();
        if (block.timestamp < phaseOneDetails.endTime) {
            if (numberMinted[msg.sender].phaseOne + amount > MAX_PER_WALLET_PER_PHASE) revert ExceedMaxPerWallet();
            numberMinted[msg.sender].phaseOne += uint8(amount);
        } else {
            if (numberMinted[msg.sender].phaseTwo + amount > MAX_PER_WALLET_PER_PHASE) revert ExceedMaxPerWallet();
            numberMinted[msg.sender].phaseTwo += uint8(amount);
        }

        _validateSender(proof);

        _mintAlpha(amount);
    }

    function mintPublic(uint256 amount) external payable {
        if (block.timestamp < phaseTwoDetails.endTime) revert PublicSaleNotStarted();
        if (numberMinted[msg.sender].phaseThree + amount > MAX_PER_WALLET_PER_PHASE) revert ExceedMaxPerWallet();
        numberMinted[msg.sender].phaseThree += uint8(amount);

        _mintAlpha(amount);
    }

    function stakeAlphaPass(uint16 amount) external {
        _safeTransferFrom(msg.sender, address(this), 1, amount, "");
        uint16 numStaked = stakeDetailsFor[msg.sender].numStaked + amount;
        if (numStaked >= 2 && stakeDetailsFor[msg.sender].numStaked < 2) stakeDetailsFor[msg.sender].stakingStart = uint64(block.timestamp);
        stakeDetailsFor[msg.sender].numStaked += amount;
    }

    function withdrawAlphaPass(uint16 amount) external {
        if (amount > stakeDetailsFor[msg.sender].numStaked) revert NotEnoughStaked();
        stakeDetailsFor[msg.sender].numStaked -= amount;
        if (stakeDetailsFor[msg.sender].numStaked < 2) stakeDetailsFor[msg.sender].stakingStart = 0;
        _safeTransferFrom(address(this), msg.sender, 1, amount, "");
    }

    function redeemForPremium() external {
        if (block.timestamp - stakeDetailsFor[msg.sender].stakingStart < MINIMUM_TIME_STAKED_FOR_PREMIUM_REDEMPTION) revert MinimumNotHit();
        if (stakeDetailsFor[msg.sender].numStaked < 2) revert NotEnoughStaked();
        stakeDetailsFor[msg.sender].numStaked -= 2;
        if (stakeDetailsFor[msg.sender].numStaked < 2) {
            stakeDetailsFor[msg.sender].stakingStart = 0;
        } else {
            stakeDetailsFor[msg.sender].stakingStart = uint64(block.timestamp);
        }

        _burn(address(this), 1, 2);
        _mint(msg.sender, PREMIUM_PASS, 1, "");
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), _toString(tokenId)));
    }

    function setUri(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    function airdrop(address[] calldata owners, uint[] calldata amounts) external onlyOwner {
        if (owners.length != amounts.length) revert();

        for (uint256 i = 0; i < owners.length; i++) {
            uint256 amount = amounts[i];
            if (totalSupply[ALPHA_PASS] + amount > FINAL_MAX_SUPPLY) revert ExceedMaxSupply();
            totalSupply[ALPHA_PASS] += amount;

            _mint(owners[i], ALPHA_PASS, amount, "");
        }
    }

    function setRoots(bytes32 _root1, bytes32 _root2) external onlyOwner {
        phaseOneDetails.root = _root1;
        phaseTwoDetails.root  = _root2;
    }

    function bumpToFinalMaxSupply() external onlyOwner {
        MAX_SUPPLY = FINAL_MAX_SUPPLY;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WrongValueSent();
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function _validateSender(bytes32[] memory _proof) private view {
        bytes32 leaf = keccak256((abi.encodePacked(msg.sender)));
        bytes32 root = _getRoot();

        if (!MerkleProof.verify(_proof, root, leaf)) {
            revert InvalidProof();
        }
    }

    function _getRoot() private view returns (bytes32) {
        return block.timestamp < phaseOneDetails.endTime ? phaseOneDetails.root : phaseTwoDetails.root;
    }

    function _mintAlpha(uint256 amount) internal {
        if (msg.value != MINT_PRICE * amount) revert WrongValueSent();
        if (totalSupply[ALPHA_PASS] + amount > MAX_SUPPLY) revert ExceedMaxSupply();
        totalSupply[ALPHA_PASS] += amount;
        _mint(msg.sender, ALPHA_PASS, amount, "");
    }

    /**
    * @dev From @chiru-labs ERC721a. Converts a uint256 to its ASCII string decimal representation.
    */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}