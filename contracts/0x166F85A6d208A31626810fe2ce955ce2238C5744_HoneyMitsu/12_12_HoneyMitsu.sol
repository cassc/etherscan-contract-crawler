// SPDX-License-Identifier: MIT
//
//                           N~<??"TBa,           ..             gT""<<<(F
//                            N,~..~~.?N,      ..MMHMMNJ        #!..~.~_(F
//                             Tm,.~..~_Tm.   .MHHHHHHHMN,    M^.~.~..(M=
//                               TNJ-~...([email protected]@[email protected]~.~(JM"`
//                                 _TBW&JMMHHHMMMMMMMHMMMMHHHMNJ&WB=
//                                    .MHHHHHHHHHMMHMMHHMHHHHHHMN,
//                                  [email protected]@[email protected]
//                                 [email protected]@[email protected]@[email protected]
//                                 [email protected]@[email protected]@HHM]
//                                [email protected]@[email protected]@HHN.
//                                [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected][
//                                [email protected]@[email protected]@[email protected]@HM]
//                                [email protected][email protected]@[email protected]\
//                                [email protected];[email protected]@HMM#"_..JMHHHM#
//                                [email protected]#[email protected]
//                                 [email protected]~._(MMHHHHMm,~.~([email protected]#~
//                                  [email protected]
//                                  ([email protected]@[email protected]@HM5
//                                   [email protected]@[email protected]@[email protected]@[email protected]
//                                    ([email protected]@[email protected]@[email protected]@HHM5
//                                      [email protected]@[email protected]
//                                       [email protected]@[email protected]@[email protected]
//                                        [email protected]@[email protected]@HHMM>
//                                        [email protected]>
//                                    Me>>uMMMMMNMMMMMMMMMMMNx>>[email protected]
//                                     [email protected]
//                                     [email protected]
//                                    [email protected]@HMMMMMMMHMNe
//                                   [email protected]
//                                   vC1MMHHHMMMMMMMMMMMMMMHHHMN1OC?
//                                     jMHHMMMMMHHHHHHHHMMMMMHMMz
//                                     jMHHMMHHHHHHHHHHHHHHMMHHMZ
//                                     dF<[email protected]#7"MP
//                                     ?HHMMHHMMMMMMMMMNMHHHMMMBC
//                                        jMHHMMMHHHHHHMMMHHM2
//                                        [email protected]@HMMMNMM$
//                                        dMHHHMMMMMMMMMMMHHMD
//                                        dMHHHHHHHHHHMHHMHHMP
//                                        dB"HMMMHM#MHMMM#MYWF
//                                        [email protected]         (BWdM5
//
//
// ”Mitsu is very angry, at the same time very thanks to CharaDao" - CBAs

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract HoneyMitsu is ERC1155, Pausable, Ownable, ERC1155Supply {
    string public name;
    string public symbol;

    address public withdrawAddress;
    uint256 public mintCost = 0.008 ether;
    uint256 public maxSupplyPerId = 1250;

    // tokenIdごとにtokenURIを設定
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC1155("") {
        name = "HoneyMitsu SBT";
        symbol = "HMS";
        setURI(0,"ipfs://bafkreihatbyjt22kurw76mt3gknsk3zztnpu2zwvtwjxot6btytvairyzu");
        pause();
    }

    //// mint functions ////
    function publicMint(
        uint256 _id,
        uint256 _mintAmount
    ) external payable whenNotPaused {
        require(msg.sender == tx.origin, "No smart contract");

        require(_mintAmount > 0, "Mint more than 1");

        require(
            _mintAmount + totalSupply(_id) <= maxSupplyPerId,
            "Claim is over the max supply"
        );

        require(mintCost * _mintAmount <= msg.value, "Not enough eth");

        _mint(msg.sender, _id, _mintAmount, "");
    }

    function adminMint(
        address to,
        uint256 _id,
        uint256 _mintAmount
    ) external payable onlyOwner {
        _mint(to, _id, _mintAmount, "");
    }

    //// URI functions ////
    function setURI(
        uint256 tokenId,
        string memory tokenURI
    ) public onlyOwner {
        _tokenURIs[tokenId] = tokenURI;
    }

    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];
        return tokenURI;
    }

    //// admin functions ////
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMintCost(uint256 _newCost) external onlyOwner {
        mintCost = _newCost;
    }

    function setMaxSupplyPerId(uint256 _newSupply) external onlyOwner {
        maxSupplyPerId = _newSupply;
    }

    //// SBT functions ////
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        require(operator == owner() || from == address(0), "this is SBT");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        require(operator == owner(), "this is SBT");
        super.setApprovalForAll(operator, approved);
    }

    //// withdraw functions ////
    function setWithdrawAddress(address _withdrawAddress) external onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw() external payable onlyOwner {
        require(
            withdrawAddress != address(0),
            "withdrawAddress shouldn't be 0"
        );
        (bool sent, ) = payable(withdrawAddress).call{
            value: address(this).balance
        }("");
        require(sent, "failed to move fund to withdrawAddress contract");
    }
}