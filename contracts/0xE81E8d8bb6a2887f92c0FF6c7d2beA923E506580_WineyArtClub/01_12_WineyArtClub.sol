// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract WineyArtClub is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public participationTokenIdCounter;
    Counters.Counter public admissionTokenIdCounter;

    uint256 public constant MAX_PARTICIPATION_SUPPLY = 5000;
    uint256 public constant MAX_ADMISSION_SUPPLY = 555;

    uint256 public participationPrice = 0.05 ether;
    uint256 public admissionPrice = 0.13 ether;

    string public baseURI;

    bool public familyAndFriendsMintActive = true;
    bool public isSaleActive = false;

    constructor() ERC721("Winey Art Club", "WAC") {}

    function setSaleActive() external onlyOwner {
        require(!isSaleActive, "WAC: sale already active");
        isSaleActive = true;

        if (familyAndFriendsMintActive) {
            familyAndFriendsMintActive = false;
        }
    }

    function setSaleInactive() external onlyOwner {
        require(isSaleActive, "WAC: sale already inactive");
        isSaleActive = false;
    }

    function mintFamilyAndFriends(
        uint256 _participationQuantity,
        uint256 _admissionQuantity
    ) external onlyOwner {
        require(
            participationTokenIdCounter.current() + _participationQuantity <=
                MAX_PARTICIPATION_SUPPLY,
            "WAC: exceeds max supply"
        );
        require(
            admissionTokenIdCounter.current() + _admissionQuantity <=
                MAX_ADMISSION_SUPPLY,
            "WAC: exceeds max supply"
        );
        require(
            familyAndFriendsMintActive,
            "WAC: family and friends mint is not active"
        );
        require(
            _participationQuantity + _admissionQuantity != 0,
            "WAC: invalid quantity"
        );

        for (uint256 i = 0; i < _participationQuantity; i++) {
            participationTokenIdCounter.increment();
            _safeMint(msg.sender, participationTokenIdCounter.current());
        }

        for (uint256 i = 0; i < _admissionQuantity; i++) {
            admissionTokenIdCounter.increment();
            _safeMint(
                msg.sender,
                MAX_PARTICIPATION_SUPPLY + admissionTokenIdCounter.current()
            );
        }
    }

    function airdropParticipation(address[] calldata _toAddresses)
        external
        onlyOwner
        mintComplianceParticipation(_toAddresses.length)
    {
        for (uint256 i = 0; i < _toAddresses.length; i++) {
            participationTokenIdCounter.increment();
            _safeMint(_toAddresses[i], participationTokenIdCounter.current());
        }
    }

    function airdropAdmission(address[] calldata _toAddresses)
        external
        onlyOwner
        mintComplianceAdmission(_toAddresses.length)
    {
        for (uint256 i = 0; i < _toAddresses.length; i++) {
            admissionTokenIdCounter.increment();
            _safeMint(
                _toAddresses[i],
                MAX_PARTICIPATION_SUPPLY + admissionTokenIdCounter.current()
            );
        }
    }

    function mintParticipation(address _toAddress, uint256 _quantity)
        external
        payable
        mintComplianceParticipation(_quantity)
    {
        require(
            msg.value == participationPrice * _quantity,
            "WAC: incorrect value"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            participationTokenIdCounter.increment();
            _safeMint(_toAddress, participationTokenIdCounter.current());
        }
    }

    function mintAdmission(address _toAddress, uint256 _quantity)
        external
        payable
        mintComplianceAdmission(_quantity)
    {
        require(_quantity > 0, "WAC: invalid quantity");
        require(
            msg.value == admissionPrice * _quantity,
            "WAC: incorrect value"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            admissionTokenIdCounter.increment();
            _safeMint(
                _toAddress,
                MAX_PARTICIPATION_SUPPLY + admissionTokenIdCounter.current()
            );
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "WAC: Transfer failed");
    }

    modifier mintComplianceParticipation(uint256 _quantity) {
        require(isSaleActive, "WAC: sale is not active");
        require(_quantity > 0, "WAC: invalid quantity");
        require(
            participationTokenIdCounter.current() + _quantity <=
                MAX_PARTICIPATION_SUPPLY,
            "WAC: exceeds max supply"
        );
        _;
    }

    modifier mintComplianceAdmission(uint256 _quantity) {
        require(isSaleActive, "WAC: sale is not active");
        require(_quantity > 0, "WAC: invalid quantity");
        require(
            admissionTokenIdCounter.current() + _quantity <=
                MAX_ADMISSION_SUPPLY,
            "WAC: exceeds max supply"
        );
        _;
    }

    function setParticipationPrice(uint256 _newPrice) external onlyOwner {
        participationPrice = _newPrice;
    }

    function setAdmissionPrice(uint256 _newPrice) external onlyOwner {
        admissionPrice = _newPrice;
    }

    function checkMintParticipationEligibility(
        /*address _toAddress,*/
        uint256 _quantity
    ) external view returns (string memory) {
        if (!isSaleActive) {
            return "WAC: sale is not active";
        }
        if (!(_quantity > 0)) {
            return "WAC: invalid quantity";
        }
        if (
            !(participationTokenIdCounter.current() + _quantity <=
                MAX_PARTICIPATION_SUPPLY)
        ) {
            return "WAC: exceeds max supply";
        }
        return "";
    }

    function checkMintAdmissionEligibility(
        /*address _toAddress,*/
        uint256 _quantity
    ) external view returns (string memory) {
        if (!isSaleActive) {
            return "WAC: sale is not active";
        }
        if (!(_quantity > 0)) {
            return "WAC: invalid quantity";
        }
        if (
            !(admissionTokenIdCounter.current() + _quantity <=
                MAX_ADMISSION_SUPPLY)
        ) {
            return "WAC: exceeds max supply";
        }
        return "";
    }

    function totalSupply() external view returns (uint256) {
        return
            admissionTokenIdCounter.current() +
            participationTokenIdCounter.current();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}