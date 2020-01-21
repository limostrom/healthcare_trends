install.packages("randomForest")
library("randomForest")

train = [training subset]
model = randomForest(as.factor([categorical DV trying to predict, i.e. NIH-funded])
						~ x1 + x2 + x3 + ... + xN, data=train)
test = [testing subset]
predictions = as.factor(predict(model, newdata = test[xvar cols 1-N]))

confusion_matrix = table(test[, [NIH-funding col]], predictions)
# to see how often the model got it right

