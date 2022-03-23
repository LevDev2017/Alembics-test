function BuildStringFromMatrix(inMatrixElements, NumRows, NumColumns) {
	let top = 0, bottom = NumRows - 1, left = 0, right = NumColumns - 1;
	let direction = 1;
	let output = "";

	while (top <= bottom && left <= right) {
		if (direction == 1) {    // moving left->right
			for (let i = left; i <= right; ++i) {
				output += (inMatrixElements[top][i] + " ");
			}
			++top;
			direction = 2;
		} 
		else if (direction == 2) {     // moving top->bottom
			for (let i = top; i <= bottom; ++i) {
			  	output += (inMatrixElements[i][right] + " ");
			}
			--right;
			direction = 3;
		} 
		else if (direction == 3) {     // moving right->left
			for (let i = right; i >= left; --i) {
			  	output += (inMatrixElements[bottom][i] + " ");
			}
			--bottom;
			direction = 4;
		} 
		else if (direction == 4) {     // moving bottom->up
			for (let i = bottom; i >= top; --i) {
			  	output += (inMatrixElements[i][left] + " ");
			}
			++left;
			direction = 1;
		}
	}

	return output;
}