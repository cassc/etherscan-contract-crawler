// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './MerkleDistributor.sol';
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract CapyMagiGenesis is ERC721A, ERC2981, Ownable, MerkleDistributor {
    using Address for address;

    enum Phases {
        NULL_PHASE,
        WHITELIST_PHASE,
        PUBLIC_PHASE
    }

    Phases phaseState = Phases.NULL_PHASE;

    struct MintConfig {
        uint16 maxMint;
        uint16 maxPhaseSupply;
    }

    MintConfig public whitelistPhase = MintConfig(1, 432);
    MintConfig public publicPhase = MintConfig(1, 1099);

    constructor(bytes32 _whiteListMerkleRoot, address royaltyReceiver) ERC721A('CapyMagi World Genesis', 'CAPYMAGI') {
        uint96 roayltyAmount = 500;
        _setDefaultRoyalty(royaltyReceiver, roayltyAmount);
        setWhitelistMerkleRoot(_whiteListMerkleRoot);
        uint256 amountForDevs = 100;
        _mint(msg.sender, amountForDevs);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mintWhitelist(bytes32[] calldata proof) external {
        MintConfig memory whitelistConfig = whitelistPhase;
        require(_numberMinted(msg.sender) < whitelistConfig.maxMint, 'Max 1 mint per wallet');
        require(totalSupply() < whitelistConfig.maxPhaseSupply, 'Exceeds supply');

        require(_isValidWhitelistProof(proof), 'You are not on the white list');
        require(phaseState != Phases.NULL_PHASE, 'Whitelist Mint is not started yet');
        _safeMint(msg.sender, whitelistConfig.maxMint);
    }

    function mint() external {
        MintConfig memory publicConfig = publicPhase;
        require(_numberMinted(msg.sender) < publicConfig.maxMint, 'Max 1 mint per wallet');
        require(totalSupply() < publicConfig.maxPhaseSupply, 'Exceeds supply');

        require(phaseState == Phases.PUBLIC_PHASE, 'Public Mint is not started yet');
        _safeMint(msg.sender, publicConfig.maxMint);
    }

    function setPhase(Phases _mintPhase) external onlyOwner {
        require(uint8(_mintPhase) < 3, 'Invalid mint phase');
        phaseState = _mintPhase;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPhase() public view returns (Phases) {
        return phaseState;
    }

    function widthdrawTo(address _address, uint256 _amount) public onlyOwner {
        payable(_address).transfer(_amount);
    }
}