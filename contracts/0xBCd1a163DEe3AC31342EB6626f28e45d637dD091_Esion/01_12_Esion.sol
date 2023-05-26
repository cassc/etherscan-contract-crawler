// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dc:;;:cokXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0x,.  ....   .c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,.  .lkKXXKOo'  .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'  .cKWMMMMMMMK;  'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl   :XMMMMMMMMMWo  .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl  .lWMMMMMMMMWk'  '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0Oc   .kNMMMMMWKl.  .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOdlc;'..    . .dWMMMWd.    'd0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKko:'.   ..,:ldxO00OOXWMMMW0l,.    .'cxXWMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc,.   .,cok0XNMMMMMMMMMMMMMMMMMWXOd:.    .ckNMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMXx:.   ':dOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOl'    ;kNMWXK0O0KNWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMW0l.  .,oONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx;   .;l;..   ..;lONMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMWKl.  .lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'     .;::;'.   ;OWMMMMMMMM
MMMMMMMMMMMMMMMMMMMXd.  .oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.  cXWMMWNOc.  .kMMMMMMMM
MMMMMMMMMMMMMMMMMWO;  .lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOdxXMMMMMMMNo   :XMMMMMMM
MMMMMMMMMMMMMMMMNd.  ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.  ;XMMMMMMM
MMMMMMMMMMMMMMMNl. .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;   lNMMMMMMM
MMMMMMMMMMMMMMNo. .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNO;   ,0MMMMMMMM
MMMMMMMMMMMMMWk.  lNMMMMMMMMMMMMMMMMMMMMMMMWKkoc::;;::lxKWMMMMMMMMMMMMMMMMMMMMKdccc:'.   :0MMMMMMMMM
MMMMMMMMMMMMMX;  ,0MMMMMMMMMMMMMMMMMMMMMMXx;. .':ccc;.  .cONMMMMMMMMMMMMMMMMMMk.      .:xNMMMMMMMMMM
MMMMMMMMMMMMMx.  oWMMMMMMMMMMMMMMMMMMMMNx'  'lolc:;:okx:. .cKMMMMMMMMMMMMMMMMM0'  'ldkKWMMMMMMMMMMMM
MMMMMMMMMMMMNc  'OMMMMMMMMMMMMMMMMMMMMXc  .dx:.      .:xx,  ,0MMMMMMMMMMMMMMMM0'  :XMMMMMMMMMMMMMMMM
MMMMMMMMMMMMK,  ;XMMMMMMMMMMMMMMMMMMMNl  'kd.          .lk'  lNMMMMMMMMMMMMMMM0'  ,KMMMMMMMMMMMMMMMM
MMMMMMMMMMMMO.  cNMMMMMMMMMMMMMMMMMMMk. .xO'            'x:  ;XMMMMMMMMMMMMMMMO.  ,KMMMMMMMMMMMMMMMM
MMMMMMMMMMMM0'  cNMMMMMMMMMMMMMMMMMMWl  ,KO.            :x,  cNMMMMMMMMMMMMMMWd.  :XMMMMMMMMMMMMMMMM
MMMMMMMMMMMMK,  ;KMMMMMMMMMMMMMMMMMMWl  '0No.         .:kc  .kWMMMMMMMMMMMMMMN:   oWMMMMMMMMMMMMMMMM
MMMMMMMMMMMMNc  .kMMMMMMMMMMMMMMMMMMMk.  cXWOl,.....;lkk;  .dNMMMMMMMMMMMMMMMO.  .kMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMk.  cXMMMMMMMMMMMMMMMMMMWd.  ,d0XNXKXXNWXl.  ,kWMMMMMMMMMMMMMMMNc   ;XMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNl  .dWMMMMMMMMMMMMMMMMMMWO:.  ..;clcclOd. 'xNMMMMMMMMMMMMMMMMWk.  .xWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMK:  .xWMMMMMMMMMMMMMMMMMMMW0dc,...    dO' :XMMMMMMMMMMMMMMMMM0,   cNMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMK:  .dNMMMMMMMMMMMMMMMMMMMMMMWXKO:  .xO. :XMMMMMMMMMMMMMMMW0,   ;KMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMXc. .cKWMMMMMMMMMMMMMMMMMMMMMMMMk.  '' .kWMMMMMMMMMMMMMMNx.   ;0MMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMNx'  .lONMMMMMMMMMMMMMMMMMMMMMMWkl:,;l0WMMMMMMMMMMMMMW0:.  .lKMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMXd,  .,lodollcclodk0XWMMMMMMMMMMWWWMMMMMMMMMMMMMNOdc.   .xWMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMXx;.              .:OWMMMMMMMMMMMMMMMMMMMMMW0l'        cXMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMWKkdollloool:.    :NMMMMMMMMMMMMMMMMMMMWKc.          .oNMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.   .xWMMMMMMMMMMMMMMMMMMWk'             .kWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;     .oNMMMMMMMMMMMMMMMMMMNx.         .:'   ,KMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:.     .oNMMMMMMMMMMMMMMMMMMNo.         ,kWk.   oWMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.       lNMMMMMMMMMMMMMMMMMMWd.         :KMMNc   '0MMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMK:        cKXK0Okxddooooooddxxkd.         cXMMMMk.   lNMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMM0,   .    .,,..                           ,KMMMMMNc   '0MMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMM0,  .,.         .,:cclll;.                .kWMMMMMMk.   oWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMM0,  .c;         .kWMMMMMWd'.               ;XMMMMMMMK;   ;KMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMXc   lo.         ,KMMMMMMNc                 oWMMMMMMMWo   .OMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMWd.  :O;          :NMMMMWWK,                .kMMMMMMMMMk.   oWMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMK,  .kk.          'olc:;;;,.                ,KMMMMMMMMMK,   :NMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMWd.  cXl                                     :XMMMMMMMMMNc   ,KMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMNl  .xK;                                     cNMMMMMMMMMWl   '0MMMMMMMMMMMMMMMM
*/

contract Esion is ERC721A, ERC2981, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    event Minted(address indexed receiver, uint256 quantity);
    event Burn(uint256 tokenId);

    struct SaleInfo {
        uint256 price;
        uint256 mintStartTime;
    }

    struct AllowedAmounts {
        uint8 raffle;
        uint8 premint;
    }

    uint256 private constant MAX_SUPPLY = 10000;
    uint8 private constant MAX_PUBLIC_MINTABLE_AMOUNT = 3;

    uint8 private constant RAFFLE_STEP = 0;
    uint8 private constant PREMINT_STEP = 1;
    uint8 private constant PUBLIC_STEP = 2;
    uint8 private constant STEP_COUNT = 3;

    uint8 private teamReservedAmount = 100;
    uint256 private raffleReservedAmount = 3107;

    string private metadataUri;
    bool private isRevealed = false;

    mapping(address => AllowedAmounts) public allowedAmounts;
    mapping(address => uint8) public walletPublicMintedAmount;

    mapping(uint8 => SaleInfo) public saleInfo;

    constructor(
        string memory _metadataUri,
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator,
        SaleInfo[] memory _saleInfoList
    ) ERC721A("ESION", "ESION") {
        metadataUri = _metadataUri;
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
        _setSaleInfo(_saleInfoList);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!isRevealed) {
            return string(abi.encodePacked(metadataUri, "prereveal"));
        }
        return string(abi.encodePacked(metadataUri, Strings.toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(metadataUri, "contractURI"));
    }

    function mint(uint8 amount, uint8 step) external payable nonReentrant whenNotPaused isNotContract {
        require(!isPublicMintEnded(), "All Mint Phase is ended");
        require(_checkMintStepValid(step), "Not exist mint step");

        uint8 _currStep = getCurrentStep();
        if (_currStep != step) {
            revert("Steps that have not started or are finished");
        }

        uint256 _price = saleInfo[step].price * amount;
        require(msg.value == _price, "Invalid ETH balance");

        require(_totalMinted() + amount <= MAX_SUPPLY, "Sold out in this step");
        if (step == RAFFLE_STEP) {
            require(_totalMinted() + amount <= raffleReservedAmount, "Sold out in this step");
            require(allowedAmounts[msg.sender].raffle - amount >= 0, "Don't have mint authority");
            allowedAmounts[msg.sender].raffle -= amount;
        } else if (step == PREMINT_STEP) {
            require(allowedAmounts[msg.sender].premint - amount >= 0, "Don't have mint authority");
            allowedAmounts[msg.sender].premint -= amount;
        } else if (step == PUBLIC_STEP) {
            require(getPublicAllowedAmounts(msg.sender) - amount >= 0, "Already exceed mint amount");
            walletPublicMintedAmount[msg.sender] += amount;
        } else {
            revert("Not exist mint step");
        }

        _mint(msg.sender, amount);
        emit Minted(msg.sender, amount);
    }

    function mintForTeam(uint8 amount) external onlyOwner {
        require(!isPublicMintEnded(), "All Mint Phase is ended");
        require(amount <= teamReservedAmount, "Already exceed mint amount");
        require(_totalMinted() + amount <= MAX_SUPPLY, "Already exceed mint amount");
        teamReservedAmount -= amount;
        _mint(msg.sender, amount);

        emit Minted(msg.sender, amount);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        emit Burn(tokenId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert("Ether transfer failed");
        }
    }

    function setMetadataUri(string calldata _metadataUri) external onlyOwner {
        metadataUri = _metadataUri;
    }

    function setIsReveal(bool _isReveal) external onlyOwner {
        isRevealed = _isReveal;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function setSaleInfo(SaleInfo[] memory _saleInfoList) external onlyOwner {
        _setSaleInfo(_saleInfoList);
    }

    function _setSaleInfo(SaleInfo[] memory _saleInfoList) private {
        require(_saleInfoList.length == STEP_COUNT, "Invalid argument");
        for (uint8 i = 0; i < _saleInfoList.length; i++) {
            saleInfo[i] = _saleInfoList[i];
        }
    }

    function setPremintAllowedAmount(address[] calldata _addressList, uint8[] calldata _amountList) external onlyOwner {
        require(_addressList.length == _amountList.length, "Invalid argument");

        for (uint256 i = 0; i < _addressList.length; i++) {
            _setAllowedAmount(_addressList[i], _amountList[i], PREMINT_STEP);
        }
    }

    function setRaffleAllowedAmount(address[] calldata _addressList, uint8[] calldata _amountList) external onlyOwner {
        require(_addressList.length == _amountList.length, "Invalid argument");

        for (uint256 i = 0; i < _addressList.length; i++) {
            _setAllowedAmount(_addressList[i], _amountList[i], RAFFLE_STEP);
        }
    }

    function setRaffleReservedAmount(uint256 _amount) external onlyOwner {
        raffleReservedAmount = _amount;
    }

    function _setAllowedAmount(
        address _address,
        uint8 _amount,
        uint8 _step
    ) private {
        require(_address != address(0), "address can't be 0");
        if (_step == PREMINT_STEP) {
            allowedAmounts[_address].premint = _amount;
        } else if (_step == RAFFLE_STEP) {
            allowedAmounts[_address].raffle = _amount;
        } else {
            revert("Not exist mint step");
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _checkMintStepValid(uint8 step) internal pure returns (bool) {
        return step < STEP_COUNT;
    }

    function getCurrentStep() public view returns (uint8) {
        uint8 _step;
        for (_step = STEP_COUNT - 1; _step >= 0; _step--) {
            if (block.timestamp >= saleInfo[_step].mintStartTime) {
                return _step;
            }
        }
        revert("Minting hasn't started yet");
    }

    function getPublicAllowedAmounts(address _address) public view returns (uint8) {
        require(_address != address(0), "address can't be 0");

        if (MAX_PUBLIC_MINTABLE_AMOUNT >= walletPublicMintedAmount[_address]) {
            return MAX_PUBLIC_MINTABLE_AMOUNT - walletPublicMintedAmount[_address];
        }
        return 0;
    }

    function isSoldOut() public view returns (bool) {
        return _totalMinted() == MAX_SUPPLY;
    }

    function isRaffleSoldOut() public view returns (bool) {
        return _totalMinted() == raffleReservedAmount;
    }

    function isPublicMintEnded() public view returns (bool) {
        return block.timestamp >= saleInfo[PUBLIC_STEP].mintStartTime + 24 hours;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    modifier isNotContract() {
        require(msg.sender == tx.origin, "Sender is not EOA");
        _;
    }
}