// SPDX-License-Identifier: UNLICENSED

/*
    ██████╗ ██╗      █████╗  ██████╗██╗  ██╗     ██████╗ ██████╗ ██████╗     ███████╗ ██████╗  ██████╗██╗███████╗████████╗██╗   ██╗
    ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝    ██╔═══██╗██╔══██╗██╔══██╗    ██╔════╝██╔═══██╗██╔════╝██║██╔════╝╚══██╔══╝╚██╗ ██╔╝
    ██████╔╝██║     ███████║██║     █████╔╝     ██║   ██║██████╔╝██████╔╝    ███████╗██║   ██║██║     ██║█████╗     ██║    ╚████╔╝
    ██╔══██╗██║     ██╔══██║██║     ██╔═██╗     ██║   ██║██╔══██╗██╔══██╗    ╚════██║██║   ██║██║     ██║██╔══╝     ██║     ╚██╔╝
    ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗    ╚██████╔╝██║  ██║██████╔╝    ███████║╚██████╔╝╚██████╗██║███████╗   ██║      ██║
    ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═════╝     ╚══════╝ ╚═════╝  ╚═════╝╚═╝╚══════╝   ╚═╝      ╚═╝

    Presented by Big Head Club
    Concept and contracts by AnAllergyToAnalogy
    Artwork designed by Mack Flavelle

    Black Orb Society minting has only one restriction, you must have a higher balance than the previous minter.
     Token artwork and metadata is fully on-chain, and is generated based on certain properties at mint-time.

    Mint cost is optional, but prestigious single-colour Orbs are only minted when the amount paid is equal to or
     greater than any amount previously paid. The lower the relative amount paid, the more colours an Orb will have.
      The number of lines an Orb has is equal to the mint order (and also the token ID).

    There is no hard limit on token supply, however the limit is implicit in that there is a finite number of Ethereum
     accounts with a higher balance. As long as the amount of Ether that exists is finite, there will always be a finite
      limit on how many Orbs can be minted.

    Any Orb minted by an address that holds another Big Head Club token will have a special red-based colour palette.
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBlackOrbMetadata.sol";

contract BlackOrbSociety is ERC721, Ownable{


    struct MintData{
        bool bhc;
        uint64 balance;
        uint64 paid;
        uint64 highestPaidAtMint;
        address minter;
    }

    constructor(address[] memory _bigHeadTokens) ERC721("Black Orb Society","ORB") {
        for(uint i = 0; i < _bigHeadTokens.length; i++){
            IERC721(_bigHeadTokens[i]).balanceOf(msg.sender);
            bigHeadTokens.push(_bigHeadTokens[i]);
        }
    }

    MintData[] mintData;
    address[] public bigHeadTokens;
    function bigHeadTokensCount() public view returns(uint){
        return bigHeadTokens.length;
    }

    address metadata;

    uint public minted;
    uint public burned;

    event Mint(uint _tokenId, uint _balance, uint _paid, uint _highestPaid);

    /*
        A note on the mint function: the exact Ether balance of an address before a function is called is not an
         property that is accessible. Neither is the total amount of gas provided to a function. Only gasleft is
          available, which returns the amount of gas remaining at the point at which it was called. Given the funky and
           unpredictable way Ethereum deals with gas, I had to fudge the numbers a little. There's no guarantee it will
            always calculate the exact balance of the address before the transaction, but it should be close.

        The gas-calculation portion of the balance-estimate code is only to prevent people from overpaying gas (which
         would be refunded) in an attempt to trick the contract into thinking their balance was lower and then getting
          many mints from a single, high-balance account by incrementally providing less gas to the transaction. Since
           gasleft will capture this overpaid amount, that's the important part. The margin of error shouldn't have a
            significant effect on the recorded balance.

        The function also can't be executed by contract addresses, this is so people can't try to cheat with flash loans
         or some other unforeseen or not-yet-devised method.
    */

    function mint() payable public{
        // This is to prevent people from overpaying gas to try trick the contract into thinking their balance was lower
        uint _gasLeft = gasleft();
        uint64 _approxTxCost = uint64((_gasLeft + 21180) * tx.gasprice);

        // This is to prevent people flash loaning large amounts of ETH to mint tokens or any other malarkey like that.
        require(msg.sender == tx.origin,"No contracts");

        uint64 _value = uint64(msg.value);
        uint64 _balance = uint64(address(msg.sender).balance) + _value + _approxTxCost;

        uint64 _highestPaid;

        if(mintData.length > 0){
            require(_balance > mintData[mintData.length - 1].balance,"insufficient balance");
            _highestPaid = mintData[mintData.length - 1].highestPaidAtMint;
        }

        if(_value > _highestPaid){
            _highestPaid = _value;
        }

         bool _bhc;
        for(uint i = 0; i < bigHeadTokens.length; i++){
            if(IERC721(bigHeadTokens[i]).balanceOf(msg.sender) > 0){
                _bhc = true;
                break;
            }
        }


        mintData.push(MintData(_bhc,_balance,_value,_highestPaid,msg.sender));

        ++minted;
        _mint(msg.sender,minted);


        emit Mint(minted,_balance,_value,_highestPaid);
    }

    function burn(uint tokenId) public {
        require(msg.sender == ownerOf(tokenId),"owner");
        _burn(tokenId);
        burned++;
    }


    function ownerWithdraw() public onlyOwner{
        require(address(this).balance > 0,"withdrawn");
        payable(msg.sender).transfer(address(this).balance);
    }

    function requiredBalance() public view returns(uint){
        if(mintData.length == 0){
            return 0;
        }else{
            return mintData[mintData.length - 1].balance + 1;
        }
    }
    function highestPaid() public view returns(uint){
        if(mintData.length == 0){
            return 0;
        }else{
            return mintData[mintData.length - 1].highestPaidAtMint;
        }
    }

    function tokenData(uint tokenId) public view returns(MintData memory){
        _requireMinted(tokenId);

        return mintData[tokenId - 1];
    }


    function tokenURI(uint256 _tokenId) public view override returns (string memory){
        require(_exists(_tokenId), "exists");

        uint64 balanceRequired;
        if(_tokenId > 1){
            balanceRequired = mintData[_tokenId - 2].balance;
        }

        return IBlackOrbMetadata(metadata).generateMetadata(
            _tokenId,
            mintData[_tokenId - 1].bhc,
            mintData[_tokenId - 1].balance,
            mintData[_tokenId - 1].paid,
            mintData[_tokenId - 1].highestPaidAtMint,
            mintData[_tokenId - 1].minter,
            balanceRequired
        );
    }

    function setMetadata(address _metadata) public onlyOwner{
        metadata = _metadata;
    }

    function addBigHeadToken(address _tokenAddress) public onlyOwner{
        IERC721(_tokenAddress).balanceOf(msg.sender);
        for(uint i = 0; i < bigHeadTokens.length; i++){
            require(bigHeadTokens[i] != _tokenAddress,"duplicate");
        }
        bigHeadTokens.push(_tokenAddress);
    }


}