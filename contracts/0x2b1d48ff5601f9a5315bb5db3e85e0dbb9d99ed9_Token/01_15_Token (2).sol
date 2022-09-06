pragma solidity 0.7.6;
pragma abicoder v2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/access/Ownable.sol";

contract Token is ERC721, Ownable {
    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {}
    
    mapping(uint256 => string) public bits;
    
    function initialDistribute(
        uint256[] memory _ids,
        address[] memory _recepients, 
        string[] memory _tokenURIs, 
        string[] memory _bits
    ) external onlyOwner() {
        require(_ids.length == _recepients.length && _ids.length == 
            _tokenURIs.length && _ids.length == _bits.length, 
            'Number of ids and recepiends dont match');
        
        for (uint256 i = 0; i < _recepients.length; i++) {
            _mint(_recepients[i], _ids[i]);
            bits[i] = _bits[i];
            _setTokenURI(_ids[i], _tokenURIs[i]);
        }
    }
    
    function mintAndSetTokenURI(uint256 _id, address _to, string memory _uri) external onlyOwner() {
        _mint(_to, _id);
        _setTokenURI(_id, _uri);
    }
}