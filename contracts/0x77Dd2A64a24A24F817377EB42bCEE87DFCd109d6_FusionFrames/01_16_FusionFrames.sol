// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract FramesInterface {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual;
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual;
    function burn(address account, uint256 id, uint256 value) public virtual;
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual;
}

contract FusionFrames is ERC721URIStorage, ERC1155Holder, Ownable {

    constructor() ERC721("Fusion Frames", "FFRAMES") {}

    mapping (uint256 => address) public approvedMinters;
    mapping (uint256 => uint256) public seriesToTokenId;

    uint256[][] public combo4 = [[1,2,4,5],[2,3,5,6],[4,5,7,8],[5,6,8,9]]; 
    uint256[] public combo9 = [1,2,3,4,5,6,7,8,9];

    bool public mintOpen = false;

    address public framesAddress;
    FramesInterface framesContract;

    function setMintStatus(bool status) public onlyOwner {
        mintOpen = status;
    }

    //Set address of the ERC1155 contract that we are interacting with
    function setFramesContractAddress(address _address) public onlyOwner {
        framesAddress = _address;
        framesContract = FramesInterface(framesAddress);
    }

    //Check that the tokenIds are from the same series and return their series number
    //Returns zero if not from same series
    //Returns the series number if all ids from same series
    function _getSeriesArray(uint256[] memory ids) internal pure returns (uint256) {
        uint256[] memory series = new uint[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            series[i] = _getSeries(ids[i]);  
            if (series[0] != series[i]) {
                return 0;
            }
        }
        return series[0];
    }

    //Get series number from tokenId
    function _getSeries(uint256 id) internal pure returns (uint256) {
        if ((id % 9) == 0) {
            return (id/9);
        } else {
            return (id/9) + 1;
        } 
    }

    //Sort an Array
    function _sort(uint256[] memory array, uint256 size) internal pure returns (uint256[] memory) {
        for (uint256 step = 0; step < size - 1; ++step) {
            uint256 swapped = 0;

            for (uint256 i = 0; i < size - step - 1; ++i) {
                if (array[i] > array[i + 1]) {
                    uint256 temp;
                    temp = array[i];
                    array[i] = array[i + 1];
                    array[i + 1] = temp;

                    swapped = 1;
                }
            }

            if (swapped == 0) {
                break;
            }
        }
        return array;
    }

    //Check if the two arrays are equal, element by element
    function _isArrayEqual(uint256[] memory array1, uint256[] memory array2) internal pure returns (bool) {
        require(array1.length == array2.length);
        for (uint256 i = 0; i < array1.length; i++) {
            if (array1[i] != array2[i]) {
                return false;
            }
        }
        return true;
    }

    //Test if the input array of token ids is an eligible combination
    function _isACombo(uint256[] memory array, uint256 series) internal view returns (bool) {
        require(array.length == 4 || array.length == 9);
        require(_getSeriesArray(array)!=0);
        bool result = false;
        uint256[] memory pArray = _reduce(array, series);
        uint256[] memory sortedArray = _sort(pArray, pArray.length);

        if (sortedArray.length == 4) {
            for (uint256 i = 0; i < combo4.length; i++) {
                if (_isArrayEqual(sortedArray, combo4[i])) {
                    result = true;
                    break;
                }
            }
        }

        if (sortedArray.length == 9) {
            if (_isArrayEqual(sortedArray, combo9)) {
                result = true;
            }
        }
        return result;
    }

    //Transform an array of tokenIds (any series) to an array of tokenIds (series 1)
    function _reduce(uint256[] memory array, uint256 series) internal pure returns (uint256[] memory) {
        uint256[] memory reducedArray = new uint256[](array.length);
        for (uint256 i = 0; i < array.length; i++) {
            reducedArray[i] = array[i] - (series - 1)*(9);
        }
        return reducedArray;
    }

    //User sends an eligible combination of Frames tokens from a particular series
    //User gets approved for minting the only ERC721 Fusion Frame for that particular series

    function sendFramesBatch(address from, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual {
        uint256 series = _getSeriesArray(ids);
        require(series!=0);
        require(_isACombo(ids,series)==true);
        framesContract.safeBatchTransferFrom(from, address(this), ids, amounts, data);
        approvedMinters[series]= msg.sender;
    }

    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;
    
    //User can mint the ERC721 Fusion Frames for a particular series, if they are approved 
    //AND if there is no other existing Fusion Frames for that particular series
    function mintFusionFrameTo(address recipient, uint256 series) public returns (uint256){
        require(mintOpen==true);
        require(approvedMinters[series]==msg.sender);
        require(seriesToTokenId[series]==0);
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        seriesToTokenId[series] = newItemId;
        return newItemId;
    }

    //Contract owner can set metadata for the Fusion Frames token
    function setFusionFramesTokenURI(uint256 tokenId, string memory _tokenURI) public virtual onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    //Contract owner can burn ERC1155 token from Frames
    function burnFrames(uint256 id, uint256 value) public virtual onlyOwner {
        framesContract.burn(address(this), id, value);
    }
    //Contract owner can burn a batch of ERC1155 tokens from Frames
    function burnFramesBatch(uint256[] memory ids, uint256[] memory values) public virtual onlyOwner {
        framesContract.burnBatch(address(this), ids, values);
    }

    //Contract owner can return ERC1155 token from Frames, in case of a user error
    function returnFrames(address to, uint256 id, uint256 value, bytes memory data) public virtual onlyOwner {
        framesContract.safeTransferFrom(address(this), to, id, value, data);
    }

    //Contract owner can return a batch of ERC1155 tokens from Frames, in case of a user error
    function returnFramesBatch(address to, uint256[] memory ids, uint256[] memory values, bytes memory data) public virtual onlyOwner {
        framesContract.safeBatchTransferFrom(address(this), to, ids, values, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
 
}