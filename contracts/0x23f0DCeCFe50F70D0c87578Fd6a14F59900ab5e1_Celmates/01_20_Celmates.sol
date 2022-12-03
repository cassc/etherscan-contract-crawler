//                                                                               
//                          &&&%   &&&&&&                                         
//                       &&&&&&&&& *&&&&&&&                                       
//                       &&&&&&&&&& &&&&&&&                                       
//                %&&&&&&&  &&&&&&& &&&&&&&                                       
//              &&&&&&&&&&& &&&&&&  &&&&&&&                                       
//             &&&&&&&&&&&  &&&&& #&&&&&&                                         
//             &&&&&&&&&&* &&&&  & &&&&&&&                                        
//             &&&&&&&&#  &&&&&&&&& &&&&&&&        #&&&&&&&&&                     
//                 %&&&&&& &&&&&&&& &&&&&&&       &&&&&&&&&&&&                    
//           &&&&&&&& &&&&.&&&&%   & &&&&&&&&    &&&&&&&&&&&&&                    
//         &&&&&&&&&&& &&& #&&&& ,  ./  &&&&&&&% &&&&&&&&&&&&%                    
//        &&&&&&&&&&& &&&&&& %  &  &&% &, &&&&&&&& &&&&&&&&&&                     
//        &&&&&&&&&& &&&&&&& & && &&&,&&/& ,&&&&&&&,&&&&&&&&                      
//        &&&&&&&&  &&&&&&& # & &(  &  &&  % &&&&&&&&&&&&&&&                      
//         &&&&&&&&&&&&&#&&  && &&&&&&&& &/    &&&&&&&&&&&&&*                     
//          &&&&&&&&&&&&&&&    &%. && & &%&(     &&&&&&&&&&&&                     
//           *&&&&&&&&&&&&&&      #& %&/& &.%&   &&&&&&&&&&&&                     
//              &&&&&&&&&&&&&     #& & & &( &&% &&&&&&&&&&&&&#                    
//                &&&&&&&&&&&&&&    &&&&&&&    *&&&&&&&&&&&&&,                    
//                 &&&&&&&&&&&&&&&&           &&&&&&&&&&&&&&&                     
//                  &&&&&&&&&&&&&&&&   &&&   &&&&&&&&&&&&&&&                      
//                   &&&&&&&&&&&&&&&  *&&&&&&&&&&&&&&&&&&&&                       
//                     &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&  &                      
//                       &&&&&&&&&&&&&&&&&&&&&&&&&&&&&  %&&                       
//                           &&&&&&&&&&&&&&&&&&&&&&&&&&&&&                        
//                         &          *. (&&&&&&&&&&&&&&%                         
//                            &&&&&&&&&&&&&&&&&&&&&&&.                            
//                                  &&&&&&&&&#                                      
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DefaultOperatorFilterer.sol";


interface ICrimereports {
    function celblocks(uint256 _celId) external view returns (uint256);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

struct DeathRow {
    uint256 startTime;
    bool status;
}

contract Celmates is
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    ERC2981,
    IERC721Receiver,
    DefaultOperatorFilterer
{
    constructor() ERC721("Cel Mates", "CELMATES") {}

    modifier isAuth() {
        require(authorised[msg.sender], "Not authorised");
        _;
    }

    using Strings for uint256;

    ICrimereports CRIMEREPORTS;

    uint256 MAX_SUPPLY = 4207;

    mapping(address => bool) authorised;

    mapping(uint256 => uint256) public celblocks;
    mapping(uint256 => uint256) public celstates;
    mapping(uint256 => int256) public cred;
    mapping(uint256 => DeathRow) public deathRowInfos;
    mapping(uint256 => string) BASE_URIS;

    bool public isCourtClosed;

    // ------------------ External ------------------ //

    function incarcerate(uint256 _crimeId) external nonReentrant {
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        require(!isCourtClosed, "Court is closed");
        uint256 celBlock = CRIMEREPORTS.celblocks(_crimeId);
        CRIMEREPORTS.safeTransferFrom(msg.sender, address(this), _crimeId);
        _safeMint(msg.sender, _crimeId);
        celblocks[_crimeId] = celBlock;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }   

    // ------------------ Public ------------------ //

    function tokenURI(uint256 _celId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_celId));
        return
            string(
                abi.encodePacked(
                    BASE_URIS[celstates[_celId]],
                    _celId.toString()
                )
            );
    }

    function deathRow(uint256 _celId, bool _status) public isAuth {
        if (_status) {
            require(
                !deathRowInfos[_celId].status,
                "Already on DeathRow"
            );
            DeathRow memory currDeathRow = DeathRow(block.timestamp, true);
            deathRowInfos[_celId] = currDeathRow;
        } else {
            require(deathRowInfos[_celId].status, "Not on DeathRow");
            DeathRow memory currDeathRow = deathRowInfos[_celId];
            currDeathRow.status = false;
            deathRowInfos[_celId] = currDeathRow;
        }
    }

    function beefUpCelmate(uint256 _celId, uint256 _newState) public isAuth {
        celstates[_celId] = _newState;
    }

    function editCred(
        uint256 _celId,
        int256 _delta
    ) public isAuth {
        require(cred[_celId] + _delta>=0, "Not enough Cred");
        cred[_celId] += _delta;
    }

    function changeCelblock(uint256 _celId, uint256 _targetBlock)
        public
        isAuth
    {
        celblocks[_celId] = _targetBlock;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721,IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721,IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721,IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ------------------ Owner ------------------ //

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        _safeMint(to, tokenId);
    }

    function setCourtClosed(bool _flag) public onlyOwner {
        isCourtClosed = _flag;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory _newBaseURI, uint256 _index)
        public
        onlyOwner
    {
        BASE_URIS[_index] = _newBaseURI;
    }

    function setAuthorised(address _address, bool _auth) external onlyOwner {
        authorised[_address] = _auth;
    }

    function setCrimereports(address _crimereports) external onlyOwner {
        CRIMEREPORTS = ICrimereports(_crimereports);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
}