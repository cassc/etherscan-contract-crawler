// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";
import "./IRenderer.sol";
import "./IArtData.sol";
import "./IArtParams.sol";

contract OffChainRenderer is IRenderer, Ownable
{
    address public _paramsAddr;
    string public _artBaseURI = "https://ipfs.io/ipfs/QmbFDGZatLBiEEWXGAf9ojRW4wkGD92NYFANxR15UP2Zj1";

    function render(
        string calldata,
        uint256,
        BaseAttributes memory atts,
        bool isSample,
        IArtData.ArtProps memory artProps
    )
        external
        view
        virtual
        override
        returns(string memory)
    {
        require(address(_paramsAddr) != address(0), "No params address");

        IParams artParams = IParams(_paramsAddr);

        string memory paramsSequence = Base64.encode(bytes(
            artParams.getParmsSequence(atts, isSample, artProps)
        ));

        return string(abi.encodePacked(_artBaseURI, "?tokenParams=", paramsSequence));
    }

    function setParamsAddr(address addr) external virtual onlyOwner {
        _paramsAddr = addr;
    }

    function setArtBaseURL(string calldata artBaseURI) external virtual onlyOwner{
        _artBaseURI = artBaseURI;
    }

}