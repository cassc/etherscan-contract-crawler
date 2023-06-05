//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//    :::::::*UUUUUUUUUS/:::::::::::::::::::::::::::::::::::::::::::*CUUUUUUUUU/:::::::::::::::::::::::::::::::::::::::::::::
//    :::::::*##########&*::::::::::::::::::::::::::::::::::::::::::b##########t:::::::::::::::::::::::::::::::::::::::::::::
//    :::::::*###########*::::::::::::::::::::::::::::::::::::::::::b##########t:::::::::::::::::::::::::::::::::::::::::::::
//    :::::::*###########C//////////////////////////////////////////M#########&S//////////////////////////////:::::::::::::::
//    :::::::*###########&##########################################&#########&##############################&*::::::::::::::
//    :::::::*################################################################################################*::::::::::::::
//    :::::::*###################################################t**M#######################################&#*::::::::::::::
//    :::::::*###########SCCCCCCCCCCCCCCCCCCCCCCCCCCU###########&:::b##########UCCCCCCCCCCCCCCCCCCCCCCCCCCCCI*:::::::::::::::
//    :::::::*###########*:::::::::::::::::::::::::::/##########&:::b#########&t:::::::::::::::::::::::::::::::::::::::::::::
//    :::::::*###########*:::::::::::::::::::::::::::*##########&:::b##########t:::::::::::::::::::::::::::::::::::::::::::::
//    :::::::*###########*:::::::::::::::::::::::::::*##########&:::b##########t:::::::::::::::::::::::::::::::::::::::::::::
//    :::::::*###########*:::::::::::::::::::::::::::*##########&:::b#########&t:::::::::::::::::::::::::::::::::::::::::::::
//    :::::::*###########*::::::::::::::::::::::::::*U&#########&:::b##########M/::::::::::::::::::::::::::::::::::::::::::::
//    :::::::*###########*::S########################&###########:::U##########&&###################################t::::::::
//    :::::::*&##########*::b###################################I:::*##############################################b:::::::::
//    ::::::::C#&########*::b#################################b/:::::*U#&########################################MC::::::::::
//    :::::::::*CbM&#####*::b&##########################&#MbS*:::::::::*CUM#&################################MbSt::::::::::::
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//    8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
//    8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
//    8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
//    888  088880 88888880     888880     088888880 0888888 0888803 88880     888880    0888880     088888880 0888888  88888888
//    88880 388   088888888888888888888 0888888880 0 0888880 08802 888888888888888888880 888880 888088888880 0 088888  88888888
//    888888   380 8888880     88888888 088888880 00  0888880 083 8888880     888888000  88888880   0888880 00  08888  88888888
//    888888800888 08888888888888888888 08888880 0000008888880 3 88888888888888888880  088888800880 088888 38000088880  8888888
//    888888888888 0888880     88888888 0888888 088888888888880 088888880     888888880 0888880    088888 38888888888880  88888
//    8888888888888888888888888888888888888888888888888888888888888888888888888888888888 88888888888888888888888888888888888888
//    8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

// SPDX-License-Identifier: MIT
// Author: Gio Vignone

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";


contract Metaversal is ERC721, Ownable, ERC721Burnable {
    
    struct Director {
        uint256 supply;
        uint256 ID;
    }

    event supplyLocked(bool _isLocked);

    event metadataFrozen(bool _isFrozen);

    event PermanentURI(string _value, uint256 indexed _id);

    uint256 public supplySpiral;

    uint256 public supplyMirror;

    uint256 public supplyRoot;

    uint256 private price;
    
    bool public mintActive;

    address private contractDeployer;

    bool public metadatafrozen;

    string private baseURI;

    uint256 private currentToken;

    bool public SupplyChangable;

    address private MetaversalVerification;

    mapping(uint256 => bool) public _canBurn;

    mapping(string => bool) private _isCodeTaken;

    mapping(uint256 => bool) public _isSequenceTaken;

    mapping(address => mapping(uint256 => uint256)) private _isAddressApproved;

    mapping(string => bool) private _isStringSet;

    mapping(uint256 => Director) private tokenCount;

    constructor(address _verification, string memory _intialbaseuri) ERC721("The Metaversal Secret Keys Collection by BT", "MVKEY") {
        currentToken = 1;
        setBaseURI(_intialbaseuri);
        supplyMirror = 11;
        supplySpiral = 22;
        supplyRoot = 33;
        tokenCount[0].supply = 0;
        tokenCount[1].supply = supplyMirror;
        tokenCount[2].supply = supplySpiral;
        tokenCount[3].supply = supplyRoot;
        tokenCount[1].ID = 1;
        tokenCount[2].ID = 12;
        tokenCount[3].ID = 23;
        SupplyChangable = true;
        contractDeployer = msg.sender;
        MetaversalVerification = _verification;
        price = 0;
    }

    function changeCurrentToken(uint256 newToken) public onlyOwner {
        currentToken = newToken;
    }

   function checkValidData(bytes32 message, bytes memory sig) public pure returns(address){
       return (recoverSigner(message, sig));
   }

   function recoverSigner(bytes32 message, bytes memory sig) public pure returns (address)
     {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }

    function splitSignature(bytes memory sig) public pure returns (uint8, bytes32, bytes32)
     {
       require(sig.length == 65);
       bytes32 r;
       bytes32 s;
       uint8 v;
       assembly {
           r := mload(add(sig, 32))
           s := mload(add(sig, 64))
           v := byte(0, mload(add(sig, 96)))
       }
       return (v, r, s);
   }

    function makeTokenBurnable(uint256 tokenId, bool setOrRestrict) public onlyOwner {
        _canBurn[tokenId] = setOrRestrict;
    }

    function burn(uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_canBurn[tokenId], "BT has not approved burning for this token yet");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function changePrice(uint256 newPrice) public onlyOwner{
        price = newPrice;
    }
    
    function changeSupply(uint256 newToken, uint256 supply, uint256 startID) public onlyOwner {
        require(SupplyChangable);
        tokenCount[newToken].supply = supply;
        tokenCount[newToken].ID = startID;
    }

    function lockSupply() public onlyOwner{
        SupplyChangable = false;
        emit supplyLocked(true);
        //Supply is permanently locked after function call
    }

    function changeVerifyAddress(address newVerification) public onlyOwner{
        MetaversalVerification = newVerification;
    }

    function changeSaleState() public onlyOwner{
        mintActive = !mintActive;
    }

    function _withdraw(uint256 amountinwei, bool getall, address payable exportaddress) onlyOwner public returns (bool){
        if(getall == true){
            exportaddress.transfer(address(this).balance);
            return true;
        }
        require(amountinwei<address(this).balance,"Contract is not worth that much yet");
        exportaddress.transfer(amountinwei);
        return true;
    }

    function mint_metaversal(bytes memory sig, uint256 desiredToken, uint256 specificSeq) public payable {
        require(desiredToken == currentToken, "Wrong desired token");
        require(msg.value >= price, "Incorrect message value");
        require(specificSeq <= tokenCount[desiredToken].supply, "Speicifc seq is above supply");
        require(specificSeq > 0, "No sequences exist under this value");
        require(specificSeq > tokenCount[desiredToken-1].supply, "No sequences exist under this value");
        require(!_isSequenceTaken[specificSeq], "Sequence already taken");
        bytes memory b = abi.encodePacked(desiredToken, specificSeq, msg.sender);
        bytes32 message = keccak256(b);
        require(MetaversalVerification == checkValidData(message, sig), "Invalid data");
        require(_isStringSet[string(b)] == false, "Token already minted");
        require(tokenCount[desiredToken].ID <= tokenCount[desiredToken].supply, "Metaversal is fully minted for this token");
        require(msg.sender != address(0) && msg.sender != address(this));
        require(_isAddressApproved[msg.sender][desiredToken] == 0, "Address is not approved to mint this token again");
        require(mintActive, "Tokens are not mintable");
        uint256 uniquetokenID = specificSeq;
        _safeMint(contractDeployer, uniquetokenID);
        _safeTransfer(contractDeployer, msg.sender, uniquetokenID, "");
        _isSequenceTaken[specificSeq] = true;
        _isStringSet[string(b)] = true;
        _isAddressApproved[msg.sender][desiredToken] = 1;
        tokenCount[desiredToken].ID += 1;
    }

    //View-state functions...

    function canAddressMint(address adr) public view returns (bool) {
        if (_isAddressApproved[adr][currentToken] == 0) {
            return true;
        }
        return false;
    }

    function checkSequence(uint256 sequence) public view returns (bool) {
        return  _isSequenceTaken[sequence];
    }

    function remainingSequences() public view returns (uint256) {
        return tokenCount[currentToken].supply - (tokenCount[currentToken].ID - 1);
    }

    function checkCurrentToken() public view returns(uint256){
        return currentToken;
    }

    //Metadata functions...

     function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string memory url) public onlyOwner {
        require(!metadatafrozen);
        baseURI = url;
    }

    function freezemetadata() onlyOwner public{
        metadatafrozen = true;
        emit metadataFrozen(true);
        for (uint256 i = 1; i <= tokenCount[currentToken].supply; i++){
            emit PermanentURI("frozen", i);
        }
        //Metadata is permanently frozen afterfunction call
    }
}