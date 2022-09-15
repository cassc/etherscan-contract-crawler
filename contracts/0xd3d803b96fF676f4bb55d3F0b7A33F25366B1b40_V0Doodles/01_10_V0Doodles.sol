// SPDX-License-Identifier: Unlicense
// Creatoor: Scroungy Labs

pragma solidity ^0.8.9;

//   ____                                                          ________                                        ___
//  /\  _`\                              __                       /\_____  \                                      /\_ \      __
//  \ \ \L\ \   __  __   _ __    ___    /\_\     ___       __     \/____//'/'      __    _____    _____      __   \//\ \    /\_\     ___
//   \ \  _ <' /\ \/\ \ /\`'__\/' _ `\  \/\ \  /' _ `\   /'_ `\        //'/'     /'__`\ /\ '__`\ /\ '__`\  /'__`\   \ \ \   \/\ \  /' _ `\
//    \ \ \L\ \\ \ \_\ \\ \ \/ /\ \/\ \  \ \ \ /\ \/\ \ /\ \L\ \      //'/'___  /\  __/ \ \ \L\ \\ \ \L\ \/\  __/    \_\ \_  \ \ \ /\ \/\ \
//     \ \____/ \ \____/ \ \_\ \ \_\ \_\  \ \_\\ \_\ \_\\ \____ \     /\_______\\ \____\ \ \ ,__/ \ \ ,__/\ \____\   /\____\  \ \_\\ \_\ \_\
//      \/___/   \/___/   \/_/  \/_/\/_/   \/_/ \/_/\/_/ \/___L\ \    \/_______/ \/____/  \ \ \/   \ \ \/  \/____/   \/____/   \/_/ \/_/\/_/
//                                                         /\____/                         \ \_\    \ \_\
//                                                         \_/__/                           \/_/     \/_/
//   ____                                      __                  ____                        __                                __
//  /\  _`\                                   /\ \__              /\  _`\                     /\ \__                            /\ \__
//  \ \,\L\_\     ___ ___       __      _ __  \ \ ,_\             \ \ \/\_\    ___     ___    \ \ ,_\   _ __     __       ___   \ \ ,_\    ____
//   \/_\__ \   /' __` __`\   /'__`\   /\`'__\ \ \ \/              \ \ \/_/_  / __`\ /' _ `\   \ \ \/  /\`'__\ /'__`\    /'___\  \ \ \/   /',__\
//     /\ \L\ \ /\ \/\ \/\ \ /\ \L\.\_ \ \ \/   \ \ \_              \ \ \L\ \/\ \L\ \/\ \/\ \   \ \ \_ \ \ \/ /\ \L\.\_ /\ \__/   \ \ \_ /\__, `\
//     \ `\____\\ \_\ \_\ \_\\ \__/.\_\ \ \_\    \ \__\              \ \____/\ \____/\ \_\ \_\   \ \__\ \ \_\ \ \__/.\_\\ \____\   \ \__\\/\____/
//      \/_____/ \/_/\/_/\/_/ \/__/\/_/  \/_/     \/__/               \/___/  \/___/  \/_/\/_/    \/__/  \/_/  \/__/\/_/ \/____/    \/__/ \/___/

import "./@burningzeppelin/contracts/access/Ownabull.sol";
import "./@burningzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC72169420.sol";

contract V0Doodles is ERC72169420, Ownabull {
    mapping(address => uint256) private _numMinted;

    uint256 private maxPerTx = 10;
    uint256 private maxPerWallet = 100;

    enum MintStatus {
        PreMint,
        Public,
        Finished
    }

    MintStatus public mintStatus;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory coverImage_
    ) ERC72169420(name_, symbol_, description_, coverImage_) {}

    function reeeeeeeee(uint256 _reeeeeeeee) public onlyOwnoor {
        _reee(_reeeeeeeee);
    }

    function changeMintStatus(MintStatus newMintStatus) public onlyOwnoor {
        require(newMintStatus != MintStatus.PreMint, "p");
        mintStatus = newMintStatus;
    }

    function preMint(address to, uint256 quantity, uint256 times) public onlyOwnoor {
        require(mintStatus == MintStatus.PreMint, "p");
        for (uint256 i = 0; i < times; i++) {
            _safeMint(address(0), to, quantity);
        }
    }

    function mintPublic(uint256 quantity) public {
        require(mintStatus == MintStatus.Public, "ms");
        require(quantity <= maxPerTx, "tx");
        require((_numMinted[msg.sender] + quantity) <= maxPerWallet, "w");
        require(totalSupply() + quantity <= maxPossibleSupply, "s");

        _safeMint(address(0), msg.sender, quantity);

        _numMinted[msg.sender] += quantity;
        if (totalSupply() == maxPossibleSupply) {
            mintStatus = MintStatus.Finished;
        }
    }

    function giftMint(uint256 quantity, address to) public {
        require(mintStatus == MintStatus.Public, "ms");
        require(quantity <= maxPerTx, "tx");
        require(totalSupply() + quantity <= maxPossibleSupply, "s");

        _safeMint(msg.sender, to, quantity);

        if (totalSupply() == maxPossibleSupply) {
            mintStatus = MintStatus.Finished;
        }
    }

    /********/

    function setBaseURI(string memory baseURI_) public onlyOwnoor {
        _setBaseURI(baseURI_);
    }

    function setPreRevealURI(string memory preRevealURI_) public onlyOwnoor {
        _setPreRevealURI(preRevealURI_);
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"", name(), "\",",
                "\"description\":\"", description, "\",",
                "\"image\":\"", coverImage, "\"}"
            )
        );
    }

    /********/

    event Yippee(uint256 indexed _howMuch);

    receive() external payable {
        emit Yippee(msg.value);
    }

    function withdraw() public onlyOwnoor {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "F");
    }

    function withdrawTokens(address tokenAddress) public onlyOwnoor {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
}

/******************/