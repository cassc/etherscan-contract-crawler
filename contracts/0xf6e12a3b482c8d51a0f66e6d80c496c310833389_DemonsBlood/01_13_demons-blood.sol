pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

abstract contract CryptoSkullsContract {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract DemonsBlood is Ownable, ReentrancyGuard, ERC1155Supply {
    using Strings for uint256;

    string private baseURI;
    CryptoSkullsContract private cryptoSkullsContract;
    address private demonicCryptoSkullsContract;
    bool public claimActive;

    mapping(uint256 => bool) public validBloodTypes;
    mapping(uint256 => bool) public claimedTokens;
    mapping(uint256 => bool) public lordsIds;

    uint256 public constant COMMON_TYPE = 0;
    uint256 public constant LORD_TYPE = 1;

    event SetBaseURI(string indexed _baseURI);

    constructor(string memory _baseUri, address cryptoSkullsContractAddress) ERC1155(_baseUri) {
        baseURI = _baseUri;
        cryptoSkullsContract = CryptoSkullsContract(cryptoSkullsContractAddress);
        claimActive = false;
        validBloodTypes[COMMON_TYPE] = true;
        validBloodTypes[LORD_TYPE] = true;

        lordsIds[9] = true;
        lordsIds[19] = true;
        lordsIds[20] = true;
        lordsIds[24] = true;
        lordsIds[27] = true;
        lordsIds[36] = true;
        lordsIds[41] = true;
        lordsIds[42] = true;
        lordsIds[43] = true;
        lordsIds[70] = true;

        emit SetBaseURI(baseURI);
    }

    function toggleClaimActive() public onlyOwner {
        claimActive = !claimActive;
    }

    function checkClaimable(uint256[] memory tokenIds) public view returns (uint256[] memory, bool[] memory) {
        uint256[] memory claimableTokenId = new uint256[](tokenIds.length);
        bool[] memory isClaimable = new bool[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            claimableTokenId[i] = tokenId;
            isClaimable[i] = !claimedTokens[tokenId];
        }

        return (claimableTokenId, isClaimable);
    }

    function claim(uint256[] memory tokenIds) public {
        uint256 issueAmount = 0;
        uint256 lordsIssueAmount = 0;

        require(claimActive, "Claim is not active at this time");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            require(cryptoSkullsContract.ownerOf(tokenId) == msg.sender, "You must be the owner of CryptoSkull");
            require(claimedTokens[tokenId] == false, "Blood for this token had already been minted");

            claimedTokens[tokenId] = true;

            if (lordsIds[tokenId]) {
                lordsIssueAmount++;
            } else {
                issueAmount++;
            }
        }

        if (lordsIssueAmount > 0) {
            _mint(msg.sender, LORD_TYPE, lordsIssueAmount, "");
        }

        if (issueAmount > 0) {
            _mint(msg.sender, COMMON_TYPE, issueAmount, "");
        }
    }

    function burnForAddress(uint256 typeId, address burnTokenAddress, uint256 amount) external {
        require(amount <= 5, "You can burn maximum of 5");
        require(msg.sender == demonicCryptoSkullsContract, "Invalid burner address");
        require(validBloodTypes[typeId], "Invalid blood type");

        _burn(burnTokenAddress, typeId, amount);
    }

    function setDemonicCryptoSkullsContract(address _demonicCryptoSkullsContract) external onlyOwner {
        demonicCryptoSkullsContract = _demonicCryptoSkullsContract;
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(validBloodTypes[typeId], "URI requested for invalid blood type");

        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, typeId.toString(), '.json'))
        : baseURI;
    }
}