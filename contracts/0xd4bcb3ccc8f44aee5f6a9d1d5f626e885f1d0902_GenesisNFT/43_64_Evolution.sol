// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../interfaces/IMintableERC721.sol';
import '../interfaces/IBurnableERC721.sol';
import '../core/SafeOwnable.sol';
import '../core/Verifier.sol';

contract Evolution is SafeOwnable, Verifier {

    event NewEvolutionDirection(IBurnableERC721 burnNFT, IERC721 evolutionNFT, bool avaliable);
    event Evoluted(address user, IBurnableERC721 burnNFT, uint burnNftId, IERC721 evolutionNFT, uint evolutionNftId);

    //burn nft => evolution nft => true
    mapping(IBurnableERC721 => mapping(IERC721 => bool)) public evolutionDirection;

    constructor(IBurnableERC721[] memory _burnNFTs, IERC721[] memory _evolutionNFTs, address _verifier) Verifier(_verifier) {
        require(_burnNFTs.length == _evolutionNFTs.length, "illegal nfts");
        for (uint i = 0; i < _burnNFTs.length; i ++) {
            require(address(_burnNFTs[i]) != address(0) && address(_evolutionNFTs[i]) != address(0), "zero address");
            require(!evolutionDirection[_burnNFTs[i]][_evolutionNFTs[i]], "direction already exist");
            evolutionDirection[_burnNFTs[i]][_evolutionNFTs[i]] = true;
            emit NewEvolutionDirection(_burnNFTs[i], _evolutionNFTs[i], true);
        }
    }

    function addEvolutionDirection(IBurnableERC721 _burnNFT, IERC721 _evolutionNFT) external onlyOwner {
        require(address(_burnNFT) != address(0) && address(_evolutionNFT) != address(0), "zero address"); 
        require(!evolutionDirection[_burnNFT][_evolutionNFT], "already exist");
        evolutionDirection[_burnNFT][_evolutionNFT] = true;
        emit NewEvolutionDirection(_burnNFT, _evolutionNFT, true);
    }

    function delEvolutionDirection(IBurnableERC721 _burnNFT, IERC721 _evolutionNFT) external onlyOwner {
        require(evolutionDirection[_burnNFT][_evolutionNFT], "not exist");
        delete evolutionDirection[_burnNFT][_evolutionNFT];
        emit NewEvolutionDirection(_burnNFT, _evolutionNFT, false);
    }

    function evolution(IBurnableERC721 _burnNFT, uint _burnNftId, IERC721 _evolutionNFT, uint _evolutionNftId, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(
            ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(address(this), msg.sender, _burnNFT, _burnNftId, _evolutionNFT , _evolutionNftId)))), _v, _r, _s) == verifier,
            "verify failed"
        );
        require(evolutionDirection[_burnNFT][_evolutionNFT], "direction not exist");
        require(_evolutionNFT.ownerOf(_evolutionNftId) == msg.sender, "illegal owner");
        _burnNFT.burn(msg.sender, _burnNftId);
        emit Evoluted(msg.sender, _burnNFT, _burnNftId, _evolutionNFT, _evolutionNftId);
    }

}