// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenParityStorage.sol";

interface ITokenParityView {
    function verifyBurnCondition(uint256 _tokenId) external view returns (bool);
    function render(uint256 _tokenId) external view returns (string memory);
}

/** 
* @author Formation.Fi.
* @notice Implementation of the contract TokenParity.
*/

contract TokenParity is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    address public investmentParity;
    bool public onChainData;
    TokenParityStorage public tokenParityStorage;
    ITokenParityView public tokenParityView;
    event MintParityToken(uint256 _tokenId);
    event BurnParityToken(uint256 _tokenId);
    event UpdateBaseURI(string _baseURI);
    event UpdateOnChainData(bool _state);

    constructor (address _tokenParityStorage, address _tokenParityView)
        ERC721("ParityToken", "PARITY"){
        require(_tokenParityStorage!= address(0),
            "Formation.Fi: zero address");
        require(_tokenParityView!= address(0),
            "Formation.Fi: zero address");
        tokenParityStorage = TokenParityStorage(_tokenParityStorage);
        tokenParityView = ITokenParityView(_tokenParityView);
    }
    

    modifier onlyInvestmentParity() {
        require(investmentParity != address(0),
            "Formation.Fi: zero address");
        require(msg.sender == investmentParity, 
            "Formation.Fi: no InvestmentParity");
        _;
    }


    function setInvestementParity(address _investmentParity) 
        external onlyOwner {
        require(_investmentParity != address(0),
            "Formation.Fi: zero address");
        investmentParity = _investmentParity;
    }  


    function setTokenParityStorage(address _tokenParityStorage) external onlyOwner {
        require(_tokenParityStorage!= address(0),
            "Formation.Fi: zero address");
        tokenParityStorage = TokenParityStorage(_tokenParityStorage);
    }


    function setTokenParityView(address _tokenParityView) external onlyOwner {
        require(_tokenParityView!= address(0),
            "Formation.Fi: zero address");
        tokenParityView = ITokenParityView(_tokenParityView);
    }


    function setOnChainData(bool _state) external onlyOwner {
        require(onChainData != _state, "Formation.Fi: no change");
        onChainData = _state;
        emit UpdateOnChainData(_state);
    }


    function setBaseURI(string calldata _tokenURI) external onlyOwner {
        baseURI = _tokenURI;
        emit UpdateBaseURI(_tokenURI);
    }


    function mint(address _account, ParityData.Position memory _position, 
        uint256 _indexEvent, uint256[3] memory _price, bool _isFirst) 
        external onlyInvestmentParity {
        require(_account!= address(0),
            "Formation.Fi: zero address");
        tokenParityStorage.updateUserPreference(_position, _indexEvent,  _price, _isFirst);
        if (_isFirst){
            _safeMint(_account,  _position.tokenId);
            emit MintParityToken( _position.tokenId);
        } 
    }

    
    function burn(uint256 _tokenId) external onlyInvestmentParity { 
        require(ownerOf(_tokenId) != address(0), 
            "Formation.Fi: zero address");   
        tokenParityView.verifyBurnCondition(_tokenId);
        _burn(_tokenId); 
        emit BurnParityToken(_tokenId);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        if (onChainData){
            return tokenParityView.render(tokenId);
        }
        else {
            string memory _string = _baseURI();
            return bytes(_string).length > 0 ? string(abi.encodePacked(_string, tokenId.toString())) : "";
        }
    }

    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    } 

}