// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Regulars.sol';

// mainnet
// mdParser             0x20fD34215489d59D323909F1D9Fc45Ef1c29666b;
// transferFunction     0x68D21E27949fDa12970EDcab4A4975aE10897d12;

interface JobsInterface {
    function hasJob(uint _regId) external view returns (bool);
    function getJobByRegId(uint _regId) external view returns (uint);
}

interface MDParserInterface {
    function getMetadataJson(uint256 tokenId) external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface RegTransferInterface {
    function regularTransfer(uint regId, uint jobId) external;
}

contract RegularsV2 is Regulars {
    JobsInterface public constant jobs = JobsInterface(0x878ADc4eF1948180434005D6f2Eb91f0AF3E0d15);     // mainnet
    MDParserInterface public mdParser;
    RegTransferInterface public transferFunction;

// View

    function getMetadataJson(uint256 tokenId) public view returns (string memory) {
        return mdParser.getMetadataJson(tokenId);
    }

// Admin

    function setMetadataParser(address addr) public onlyOwner() {
        mdParser = MDParserInterface(addr);
    }

    function setTransferFunction(address addr) public onlyOwner() {
        transferFunction = RegTransferInterface(addr);
    }

// Overrides

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        uint256 jobId = jobs.getJobByRegId(tokenId);
        if (jobId != 0) {
            transferFunction.regularTransfer(tokenId, jobId);
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return mdParser.tokenURI(tokenId);
    }

}