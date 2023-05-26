// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Pausable.sol";
import "./Billionaire.sol";

contract Cyborg is IERC721Receiver, ERC721Enumerable, Pausable {
    struct Trait {
        uint8 index_1;
        uint8 index_2;
    }
    bool public isBurnEnabled;
    string public baseURI;
    address payable public billionaireAddress;
    address[] public users;
    mapping(uint256 => Trait) public traitsPerToken;
    mapping(uint256 => uint256) public tokens;
    mapping(uint256 => bool) public ismerged;
    Billionaire billionaireContract;

    event LogMint(address indexed _caller, uint256 _token_1, uint256 _token_2, uint256 _trait_1, uint256 _trait_2);
    event ChangeIsBurnEnabled(bool _isBurnEnabled);
    event ChangeBaseURI(string _baseURI);

    constructor(address payable _addresssContract) ERC721("Cyborg Billionaire Club ", "CBC") {
        require(
            _addresssContract != address(0),
            "Cyborg Billionaire Club: address contract is Zero address"
        );
        billionaireAddress = payable(_addresssContract);
        billionaireContract = Billionaire(billionaireAddress);
    }

    function getToken(uint256 _id) external view returns (uint256) {
        return tokens[_id];
    }

    function getTraits(uint256 _id) external view returns (Trait memory) {
        return traitsPerToken[_id];
    }

    function getusers(uint256 _id) external view returns (address) {
        return users[_id];
    }

    function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
        emit ChangeBaseURI(_tokenBaseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setIsBurnEnabled(bool _isBurnEnabled) external onlyOwner {
        isBurnEnabled = _isBurnEnabled;
        emit ChangeIsBurnEnabled(_isBurnEnabled);
    }

    function isTokenMerged(uint256 _token)
        external
        view
        returns (bool)
    {
        return ismerged[_token];
    }

    function mergeNFT(
        uint256 _token_1,
        uint256 _token_2,
        uint8 _trait_1,
        uint8 _trait_2
    ) external whenNotPaused {
        address _caller = msg.sender;

        require((_trait_1 >=1) && (_trait_1 <=7),
            "Cyborg Billionaire Club: invalid trait index");

        require((_trait_2 >=1) && (_trait_2 <=7),
            "Cyborg Billionaire Club: invalid trait index");
        
        require(
            (billionaireContract.ownerOf(_token_1) == msg.sender) &&
                (billionaireContract.ownerOf(_token_2) == msg.sender),
            "Cyborg Billionaire Club: Caller is not the owner of tokens"
        );
        require(
            ismerged[_token_1] == false,
            "Cyborg Billionaire Club: Token is already merged"
        );

         require(
            billionaireContract.isApprovedForAll(_caller, address(this)),
            "Cyborg Billionaire Club: Cyborc contract is not approved for tokens");
            
        Trait memory _trait = Trait(_trait_1, _trait_2);
        traitsPerToken[_token_1] = _trait;
        tokens[_token_1] = _token_2;
        users.push(msg.sender);
        _safeMint(msg.sender, _token_1);
        ismerged[_token_1] = true;

        billionaireContract.safeTransferFrom(msg.sender, address(this), _token_2); 
        billionaireContract.burn(_token_2); 

        emit LogMint(msg.sender, _token_1, _token_2, _trait_1,  _trait_2);
    }

    function burn(uint256 _id) external {
        require(isBurnEnabled, "Cyborg Billionaire Club: burning disabled");
        require(
            _isApprovedOrOwner(msg.sender, _id),
            "Cyborg Billionaire Club: burn caller is not owner nor approved"
        );
        _burn(_id);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}