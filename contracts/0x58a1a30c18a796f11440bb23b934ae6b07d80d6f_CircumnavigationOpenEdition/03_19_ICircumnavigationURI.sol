pragma solidity 0.8.4;

interface ICircumnavigationURI {
    function cITokenURI() external view returns (string memory);
    function cIITokenURI() external view returns (string memory);
    function cIIITokenURI(uint8 niftyType) external view returns (string memory);    
    function cIOneOfOneTokenURI() external view returns (string memory);    
    function cIIOneOfOneTokenURI() external view returns (string memory);
}