// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/erc721a/contracts/extensions/ERC721AQueryable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract Pogs is ERC721AQueryable, Ownable, ERC2981 {
    using ECDSA for bytes32;

    enum ActiveSession {
        INACTIVE,
        ALLOWLIST,
        WAITLIST,
        PUBLIC
    }

    // CONSTANTS
    uint256 constant MAX_SUPPLY = 4_444;
    uint256 constant TICKETS_PER_BIN = 256;
    uint256 constant TICKET_BINS = 75; // Starting Amount of Bins: STARTING_TICKETS / 256 + 1
    uint256 constant STARTING_TICKETS = 19_200; // TICKET_BINS * TICKETS_PER_BIN

    // PRIVATE VARS
    string private baseURI;
    string private unrevealedURI;
    uint256 private _royaltyPermille = 40; // supports 1 decimal place ex. 40 = 4.0%

    // PUBLIC VARS
    bool public isRevealed = false;
    address public allowListSigner;
    address public withdrawAddress;
    address public royaltyAddress;
    uint256 public mintPrice = 0.049 ether;
    uint256 public totalTickets;
    mapping(uint256 => uint256) public ticketMap;
    ActiveSession public activeSession = ActiveSession.INACTIVE;

    constructor(
        address _signer,
        address _withdrawer,
        address _royalties
    ) ERC721A("Pogs", "POG") {
        require(_signer != address(0x00), "Cannot be zero address");
        require(_withdrawer != address(0x00), "Cannot be zero address");
        require(_royalties != address(0x00), "Cannot be zero address");
        allowListSigner = _signer;
        withdrawAddress = _withdrawer;
        royaltyAddress = _royalties;
        //initialize tickets
        _addTickets(STARTING_TICKETS);
    }

    function mint(uint256 amount) external payable {
        require(activeSession == ActiveSession.PUBLIC, "Minting Not Active");
        require(msg.sender == tx.origin, "EOA Only");
        require(_totalMinted() + amount <= MAX_SUPPLY, "Max amount reached");
        require(msg.value >= mintPrice * amount, "Did not send enough ether");

        //mint
        _mint(_msgSender(), amount);
    }

    function mintWithTicket(
        uint256[] calldata ticketNumbers,
        bytes[] calldata signatures
    ) external payable {
        require(ticketNumbers.length < 3, "Max 2 Tickets");
        require(ticketNumbers.length == signatures.length, "Mismatch Arrays");
        require(
            _totalMinted() + ticketNumbers.length <= MAX_SUPPLY,
            "Max amount reached"
        );
        require(
            msg.value >= mintPrice * ticketNumbers.length,
            "Did not send enough ether"
        );

        for (uint256 i; i < ticketNumbers.length; i++) {
            //get ticket bin and ticket bit
            (uint256 ticketBin, uint256 ticketBit) = _getTicketBinAndBit(
                ticketNumbers[i]
            );

            (bool _isValid, string memory reason) = _verifyTicket(
                _msgSender(), // ensures only verified user can mint
                ticketNumbers[i], // ensures a ticket cant be used twice
                ticketBin,
                ticketBit,
                uint8(activeSession), // ensures ticket can only be used for current session
                signatures[i]
            );

            require(_isValid, reason);
            _claimTicket(ticketBin, ticketBit); // account for used ticket
        }

        //mint
        _mint(_msgSender(), ticketNumbers.length);
    }

    function verifyTicket(
        address user,
        uint256 ticketNumber,
        uint8 session,
        bytes memory signature
    ) public view returns (bool _isValid) {
        //get ticket bin and ticket bit
        (uint256 ticketBin, uint256 ticketBit) = _getTicketBinAndBit(
            ticketNumber
        );

        (_isValid, ) = _verifyTicket(
            user, // ensures only verified user can mint
            ticketNumber, // ensures a ticket cant be used twice
            ticketBin,
            ticketBit,
            session, // ensures ticket can only be used for current session
            signature
        );
    }

    function _verifyTicket(
        address user,
        uint256 ticketNumber,
        uint256 ticketBin,
        uint256 ticketBit,
        uint8 session,
        bytes memory signature
    ) private view returns (bool isValid, string memory reason) {
        if (ticketNumber > totalTickets)
            return (false, "Invalid Ticket Number");
        //check for valid signature
        if (
            allowListSigner ==
            getTicket(user, ticketNumber, session)
                .toEthSignedMessageHash()
                .recover(signature)
        ) {
            //ensure ticket hasnt been used yet
            isValid = !_isTicketClaimed(ticketBin, ticketBit);
            if (!isValid) reason = "Claimed Ticket";
        } else reason = "Invalid Ticket";
    }

    function _getTicketBinAndBit(
        uint256 _ticketNumber
    ) private pure returns (uint256 _bin, uint256 _bit) {
        //No chance of overflow
        unchecked {
            _bin = _ticketNumber / TICKETS_PER_BIN;
            _bit = _ticketNumber % TICKETS_PER_BIN;
        }
    }

    function _isTicketClaimed(
        uint256 _bin,
        uint256 _bit
    ) private view returns (bool isClaimed) {
        //ensure ticket hasnt been used yet
        uint256 verifyBit = (ticketMap[_bin] >> _bit) & uint256(1);
        if (verifyBit == 0) return true;
    }

    function _claimTicket(uint256 ticketBin, uint256 ticketBit) private {
        ticketMap[ticketBin] =
            ticketMap[ticketBin] &
            ~(uint256(1) << ticketBit);
    }

    //create an unsigned ticket
    function getTicket(
        address user,
        uint256 ticketNumber,
        uint8 session
    ) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(user, ticketNumber, session));
        return hash;
    }

    function addTickets(uint256 amount) external onlyOwner {
        _addTickets(amount);
    }

    function _addTickets(uint256 amount) private {
        //store how many current bins exist
        uint256 currentBins;
        if (totalTickets > 0) currentBins = totalTickets / 256 + 1;

        //calc new amount of bins needed with new tickets added
        totalTickets += amount;
        uint256 requiredBins = totalTickets / 256 + 1;

        //check if we need to add bins
        if (requiredBins > currentBins) {
            uint256 binsToAdd = requiredBins - currentBins;
            for (uint256 i; i < binsToAdd; i++) {
                ticketMap[currentBins + i] = type(uint256).max;
            }
        }
    }

    function tokensOfOwner(
        address _owner
    ) external view returns (uint256[] memory) {
        return _tokensOfOwner(_owner);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        if (!isRevealed) return unrevealedURI;
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) public view override returns (address receiver, uint256 royaltyAmount) {
        return (royaltyAddress, (salePrice * _royaltyPermille) / 1000);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // OWNER ONLY //
    function setRoyaltyPermille(uint256 number) external onlyOwner {
        _royaltyPermille = number;
    }

    function setRoyaltyAddress(address addr) external onlyOwner {
        require(addr != address(0x00), "Cannot be zero address");
        royaltyAddress = addr;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function setUnrevealedURI(string calldata uri) external onlyOwner {
        unrevealedURI = uri;
    }

    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function mintForTeam(address receiver, uint16 amount) external onlyOwner {
        require(_totalMinted() + amount <= MAX_SUPPLY, "Max amount reached");
        _safeMint(receiver, amount);
    }

    function setAllowListSigner(address _signer) external onlyOwner {
        require(_signer != address(0x00), "Cannot be zero address");
        allowListSigner = _signer;
    }

    // session input should be:
    // 0 = Inactive, 1 = AllowList, 2 = Waitlist, 3 = Public Sale
    function setSession(uint8 session) external onlyOwner {
        activeSession = ActiveSession(session);
    }

    function withdraw() external {
        require(_msgSender() == withdrawAddress, "Withdraw address only");
        uint256 totalAmount = address(this).balance;
        bool sent;

        (sent, ) = withdrawAddress.call{value: totalAmount}("");
        require(sent, "Main: Failed to send funds");
    }

    function setWithdrawAddress(address addr) external onlyOwner {
        require(addr != address(0x00), "Cannot be zero address");
        withdrawAddress = addr;
    }

    function getWithdrawBalance() external view returns (uint256) {
        // To access the amount of ether the contract has
        return address(this).balance;
    }

    //  ADMIN ONLY //
    mapping(address => bool) private _admins;

    modifier onlyAdmin() {
        require(_admins[msg.sender], "Only Admins");
        _;
    }

    function burn(uint256 tokenId) external onlyAdmin {
        _burn(tokenId);
    }

    function addAdmin(address addr) external onlyOwner {
        require(addr != address(0x00), "Cannot be zero address");
        _admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }

    function isAdmin(address addr) external view returns (bool) {
        return _admins[addr];
    }

    receive() external payable {}

    fallback() external payable {}
}