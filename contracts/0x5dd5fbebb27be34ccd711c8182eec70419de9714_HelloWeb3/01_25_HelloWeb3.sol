// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./FOMOPASS.sol";
import "./RoyaltySplits.sol";

/// @author FOMOLOL (fomolol.com)

/**
 *
 * ██╗░░██╗███████╗██╗░░░░░██╗░░░░░░█████╗░███╗░░██╗███████╗████████╗██╗
 * ██║░░██║██╔════╝██║░░░░░██║░░░░░██╔══██╗████╗░██║██╔════╝╚══██╔══╝██║
 * ███████║█████╗░░██║░░░░░██║░░░░░██║░░██║██╔██╗██║█████╗░░░░░██║░░░██║
 * ██╔══██║██╔══╝░░██║░░░░░██║░░░░░██║░░██║██║╚████║██╔══╝░░░░░██║░░░╚═╝
 * ██║░░██║███████╗███████╗███████╗╚█████╔╝██║░╚███║██║░░░░░░░░██║░░░██╗
 * ╚═╝░░╚═╝╚══════╝╚══════╝╚══════╝░╚════╝░╚═╝░░╚══╝╚═╝░░░░░░░░╚═╝░░░╚═╝
 * @title HELLO NFT!
 */
contract HelloWeb3 is RoyaltySplits, FOMOPASS {
	constructor(
		string memory _symbol,
		string memory _name,
		string memory _uri
	) FOMOPASS(_symbol, _name, _uri, addresses, splits) {}
}

/*
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy of this...HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 *   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER...SOFTWARE.
 *
 *   Art by EON (@Colette00000), and concept by Jiwon (@dimanchelunch) and Youngsun (@youngsunlive)
 *   Twitter @hello_web3
 *
 *   Smart contract developed for Hello NFT! by FOMOLOL LLC
 */